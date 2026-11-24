//
// Created by aeyeo on 2026/11/23.
//

#include "modbusWorker.h"

#include <QModbusReply>
#include <QString>
#include <QTimer>
#include <QVariant>

#include <cmath>

void modbusWorker::init(const ModbusConnectionSettings &settings)
{
    if (m_pollTimer) {
        return;
    }
    if (settings.pollingIntervalMs <= 0) {
        return;
    }
    m_pollingIntervalMs = settings.pollingIntervalMs;

    using StateSignal = void (modbusWorker::*)(QModbusDevice::State);
    using ErrorSignal = void (modbusWorker::*)(QModbusDevice::Error);

    const auto initializeClient = [this](QModbusTcpClient *&client, const QString &name,
                                         const ModbusEndpoint &endpoint, StateSignal stateSignal,
                                         ErrorSignal errorSignal) {
        if (client) {
            return;
        }

        client = new QModbusTcpClient(this);
        client->setConnectionParameter(QModbusDevice::NetworkAddressParameter, endpoint.address);
        client->setConnectionParameter(QModbusDevice::NetworkPortParameter, endpoint.port);
        client->setObjectName(name);
        client->setTimeout(1000);
        client->setNumberOfRetries(1);
        auto *reconnectTimer = new QTimer(client);
        reconnectTimer->setSingleShot(true);
        reconnectTimer->setInterval(1000);
        const auto connectClient = [client, reconnectTimer] {
            if (client->state() != QModbusDevice::UnconnectedState) {
                return;
            }
            if (!client->connectDevice()
                && client->state() == QModbusDevice::UnconnectedState
                && !reconnectTimer->isActive()) {
                reconnectTimer->start();
            }
        };
        connect(reconnectTimer, &QTimer::timeout, this, connectClient);
        connect(client, &QModbusTcpClient::stateChanged, this,
                [reconnectTimer](QModbusDevice::State state) {
                    if (state == QModbusDevice::UnconnectedState) {
                        if (!reconnectTimer->isActive()) {
                            reconnectTimer->start();
                        }
                    } else {
                        reconnectTimer->stop();
                    }
                });
        connect(client, &QModbusTcpClient::stateChanged, this, stateSignal);
        connect(client, &QModbusTcpClient::errorOccurred, this, errorSignal);
        connect(client, &QModbusTcpClient::stateChanged, this,
                [this, client](QModbusDevice::State state) {
                    if (client == m_6250 && m_resetInProgress
                        && state != QModbusDevice::ConnectedState) {
                        failReset(m_resetSequence, QStringLiteral("m_6250 disconnected"));
                    }
                });
        connect(client, &QModbusTcpClient::stateChanged, this,
                [this, client](QModbusDevice::State state) {
                    if (!m_emergency || state != QModbusDevice::ConnectedState) {
                        return;
                    }
                    if (client == m_6250) {
                        writeEmergency6250();
                    } else if (client == m_6224) {
                        writeEmergency6224();
                    }
                });
        connectClient();
    };

    initializeClient(m_6250, QStringLiteral("m_6250"), settings.m6250,
                     &modbusWorker::stateChanged_6250, &modbusWorker::errorOccurred_6250);
    initializeClient(m_6217, QStringLiteral("m_6217"), settings.m6217,
                     &modbusWorker::stateChanged_6217, &modbusWorker::errorOccurred_6217);
    initializeClient(m_6224, QStringLiteral("m_6224"), settings.m6224,
                     &modbusWorker::stateChanged_6224, &modbusWorker::errorOccurred_6224);

    m_pollTimer = new QTimer(this);
    connect(m_pollTimer, &QTimer::timeout, this, &modbusWorker::pollDevices);
    m_pollTimer->start(m_pollingIntervalMs);
}

bool modbusWorker::setPollingInterval(int intervalMs)
{
    if (m_pollTimer || intervalMs <= 0) {
        return false;
    }

    m_pollingIntervalMs = intervalMs;
    return true;
}

void modbusWorker::setEmergency(bool open)
{
    m_emergency = open;
    if (!open) {
        return;
    }

    writeEmergency6250();
    writeEmergency6224();
}

void modbusWorker::writeEmergency6250()
{
    QModbusDataUnit request(QModbusDataUnit::Coils, 19, 4);
    for (uint i = 0; i < request.valueCount(); ++i) {
        request.setValue(i, 1);
    }
    writeDevice(m_6250, QStringLiteral("m_6250"), request);
}

void modbusWorker::writeEmergency6224()
{
    QModbusDataUnit request(QModbusDataUnit::HoldingRegisters, 0, 2);
    request.setValue(0, 0);
    request.setValue(1, 0);
    writeDevice(m_6224, QStringLiteral("m_6224"), request);
}

void modbusWorker::writeValveRegister(int address, double value)
{
    if (m_emergency) {
        emit writeFailed(QStringLiteral("m_6224"), QStringLiteral("Emergency mode is active"));
        return;
    }
    if (address < 0 || address > 1) {
        emit writeFailed(QStringLiteral("m_6224"), QStringLiteral("Invalid valve register address"));
        return;
    }
    if (!std::isfinite(value) || value < 0 || value > 4096) {
        emit writeFailed(QStringLiteral("m_6224"), QStringLiteral("Valve register value is out of range (0-4096)"));
        return;
    }

    QModbusDataUnit request(QModbusDataUnit::HoldingRegisters,
                            static_cast<quint16>(address), 1);
    request.setValue(0, static_cast<quint16>(std::round(value)));
    writeDevice(m_6224, QStringLiteral("m_6224"), request);
}

void modbusWorker::reset()
{
    if (m_resetInProgress) {
        return;
    }

    const quint64 sequence = ++m_resetSequence;
    m_resetInProgress = true;
    if (!m_6250 || m_6250->state() != QModbusDevice::ConnectedState) {
        failReset(sequence, QStringLiteral("m_6250 is not connected"));
        return;
    }

    readResetRegister(sequence, ResetStage::ReadingInitialValue);
}

bool modbusWorker::isResetCurrent(quint64 sequence, ResetStage stage) const
{
    return m_resetInProgress && m_resetSequence == sequence && m_resetStage == stage;
}

void modbusWorker::readResetRegister(quint64 sequence, ResetStage stage)
{
    if (!m_resetInProgress || m_resetSequence != sequence) {
        return;
    }
    m_resetStage = stage;
    if (!m_6250 || m_6250->state() != QModbusDevice::ConnectedState) {
        failReset(sequence, QStringLiteral("m_6250 is not connected"));
        return;
    }

    const QModbusDataUnit request(QModbusDataUnit::HoldingRegisters, 304, 1);
    QModbusReply *reply = m_6250->sendReadRequest(request, 1);
    if (!reply) {
        failReset(sequence, m_6250->errorString());
        return;
    }

    const auto finishRead = [this, reply, sequence, stage] {
        reply->deleteLater();
        if (!isResetCurrent(sequence, stage)) {
            return;
        }
        if (reply->error() != QModbusDevice::NoError) {
            failReset(sequence, reply->errorString());
            return;
        }

        const QModbusDataUnit result = reply->result();
        if (result.registerType() != QModbusDataUnit::HoldingRegisters
            || result.startAddress() != 304 || result.valueCount() != 1) {
            failReset(sequence, QStringLiteral("Unexpected response for holding register 304"));
            return;
        }

        const quint16 value = result.value(0);
        switch (stage) {
        case ResetStage::ReadingInitialValue:
            writeResetRegister(sequence, static_cast<quint16>(value | 0x0010),
                               ResetStage::SettingResetBit);
            break;
        case ResetStage::ReadingBeforeClear:
            writeResetRegister(sequence, static_cast<quint16>(value & 0xFFEF),
                               ResetStage::ClearingResetBit);
            break;
        case ResetStage::VerifyingResetBit:
            if ((value & 0x0010) != 0) {
                failReset(sequence, QStringLiteral("Verification failed: reset bit 4 is still set"));
                return;
            }
            m_resetInProgress = false;
            m_resetStage = ResetStage::Idle;
            emit resetCompleted();
            break;
        default:
            failReset(sequence, QStringLiteral("Unexpected reset read stage"));
            break;
        }
    };

    if (reply->isFinished()) {
        finishRead();
    } else {
        connect(reply, &QModbusReply::finished, this, finishRead);
    }
}

void modbusWorker::writeResetRegister(quint64 sequence, quint16 value, ResetStage stage)
{
    if (!m_resetInProgress || m_resetSequence != sequence) {
        return;
    }
    m_resetStage = stage;
    if (!m_6250 || m_6250->state() != QModbusDevice::ConnectedState) {
        failReset(sequence, QStringLiteral("m_6250 is not connected"));
        return;
    }

    QModbusDataUnit request(QModbusDataUnit::HoldingRegisters, 304, 1);
    request.setValue(0, value);
    QModbusReply *reply = m_6250->sendWriteRequest(request, 1);
    if (!reply) {
        failReset(sequence, m_6250->errorString());
        return;
    }

    const auto finishWrite = [this, reply, sequence, stage] {
        reply->deleteLater();
        if (!isResetCurrent(sequence, stage)) {
            return;
        }
        if (reply->error() != QModbusDevice::NoError) {
            failReset(sequence, reply->errorString());
            return;
        }

        if (stage == ResetStage::SettingResetBit) {
            m_resetStage = ResetStage::WaitingToClearBit;
            QTimer::singleShot(1000, Qt::PreciseTimer, this, [this, sequence] {
                if (isResetCurrent(sequence, ResetStage::WaitingToClearBit)) {
                    readResetRegister(sequence, ResetStage::ReadingBeforeClear);
                }
            });
        } else if (stage == ResetStage::ClearingResetBit) {
            m_resetStage = ResetStage::WaitingToVerify;
            QTimer::singleShot(1000, Qt::PreciseTimer, this, [this, sequence] {
                if (isResetCurrent(sequence, ResetStage::WaitingToVerify)) {
                    readResetRegister(sequence, ResetStage::VerifyingResetBit);
                }
            });
        } else {
            failReset(sequence, QStringLiteral("Unexpected reset write stage"));
        }
    };

    if (reply->isFinished()) {
        finishWrite();
    } else {
        connect(reply, &QModbusReply::finished, this, finishWrite);
    }
}

void modbusWorker::failReset(quint64 sequence, const QString &error)
{
    if (!m_resetInProgress || m_resetSequence != sequence) {
        return;
    }

    m_resetInProgress = false;
    m_resetStage = ResetStage::Idle;
    emit resetFailed(QStringLiteral("Reset aborted; bit 4 may remain set: %1").arg(error));
}

void modbusWorker::writeDevice(QModbusTcpClient *client, const QString &deviceName,
                               const QModbusDataUnit &request)
{
    if (!client || client->state() != QModbusDevice::ConnectedState) {
        emit writeFailed(deviceName, QStringLiteral("Device is not connected"));
        return;
    }

    QModbusReply *reply = client->sendWriteRequest(request, 1);
    if (!reply) {
        emit writeFailed(deviceName, client->errorString());
        return;
    }

    const auto finishWrite = [this, reply, deviceName, request] {
        reply->deleteLater();
        if (reply->error() == QModbusDevice::NoError) {
            emit writeCompleted(deviceName, request);
        } else {
            emit writeFailed(deviceName, reply->errorString());
        }
    };
    if (reply->isFinished()) {
        finishWrite();
    } else {
        connect(reply, &QModbusReply::finished, this, finishWrite);
    }
}

void modbusWorker::pollDevices()
{
    readDevice(m_6250, &m_6250PendingReply, QStringLiteral("m_6250"),
               QModbusDataUnit::Coils, 23);
    readDevice(m_6217, &m_6217PendingReply, QStringLiteral("m_6217"),
               QModbusDataUnit::HoldingRegisters, 8);
}

void modbusWorker::readDevice(QModbusTcpClient *client, QPointer<QModbusReply> *pendingReply,
                              const QString &deviceName,
                              QModbusDataUnit::RegisterType registerType, quint16 valueCount)
{
    if (!client || client->state() != QModbusDevice::ConnectedState || *pendingReply) {
        return;
    }

    const QModbusDataUnit request(registerType, 0, valueCount);
    QModbusReply *reply = client->sendReadRequest(request, 1);
    if (!reply) {
        emit readFailed(deviceName, client->errorString());
        return;
    }

    *pendingReply = reply;
    const auto finishRead = [this, reply, pendingReply, deviceName] {
        if (*pendingReply == reply) {
            *pendingReply = nullptr;
        }

        reply->deleteLater();
        if (reply->error() == QModbusDevice::NoError) {
            emit readCompleted(deviceName, reply->result());
        } else {
            emit readFailed(deviceName, reply->errorString());
        }
    };
    if (reply->isFinished()) {
        finishRead();
    } else {
        connect(reply, &QModbusReply::finished, this, finishRead);
    }
}
