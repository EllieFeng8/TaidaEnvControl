//
// Created by aeyeo on 2026/11/23.
//

#ifndef TAIDAENVCONTROLAPP_MODBUSWORKER_H
#define TAIDAENVCONTROLAPP_MODBUSWORKER_H

#include <QObject>
#include <QModbusDataUnit>
#include <QModbusTcpClient>
#include <QPointer>
#include <QString>

class QModbusReply;
class QTimer;

struct ModbusEndpoint {
    QString address;
    int port = 502;
};

struct ModbusConnectionSettings {
    ModbusEndpoint m6250{QStringLiteral("192.168.1.201"), 502};
    ModbusEndpoint m6217{QStringLiteral("192.168.1.202"), 502};
    ModbusEndpoint m6224{QStringLiteral("192.168.1.203"), 502};
    int pollingIntervalMs = 1000;
};

class modbusWorker : public QObject {
    Q_OBJECT

public:
    void init(const ModbusConnectionSettings &settings = {});
    bool setPollingInterval(int intervalMs);
    void setEmergency(bool open);
    void writeValveRegister(int address, double value);
    void reset();

signals:
    void stateChanged_6250(QModbusDevice::State state);
    void errorOccurred_6250(QModbusDevice::Error error);
    void stateChanged_6217(QModbusDevice::State state);
    void errorOccurred_6217(QModbusDevice::Error error);
    void stateChanged_6224(QModbusDevice::State state);
    void errorOccurred_6224(QModbusDevice::Error error);
    void readCompleted(const QString &deviceName, const QModbusDataUnit &data);
    void readFailed(const QString &deviceName, const QString &error);
    void writeCompleted(const QString &deviceName, const QModbusDataUnit &data);
    void writeFailed(const QString &deviceName, const QString &error);
    void resetCompleted();
    void resetFailed(const QString &error);

private:
    enum class ResetStage {
        Idle,
        ReadingInitialValue,
        SettingResetBit,
        WaitingToClearBit,
        ReadingBeforeClear,
        ClearingResetBit,
        WaitingToVerify,
        VerifyingResetBit
    };

    void writeEmergency6250();
    void writeEmergency6224();
    void writeDevice(QModbusTcpClient *client, const QString &deviceName,
                     const QModbusDataUnit &request);
    bool isResetCurrent(quint64 sequence, ResetStage stage) const;
    void readResetRegister(quint64 sequence, ResetStage stage);
    void writeResetRegister(quint64 sequence, quint16 value, ResetStage stage);
    void failReset(quint64 sequence, const QString &error);
    void pollDevices();
    void readDevice(QModbusTcpClient *client, QPointer<QModbusReply> *pendingReply,
                    const QString &deviceName, QModbusDataUnit::RegisterType registerType,
                    quint16 valueCount);

    QModbusTcpClient *m_6250 = nullptr;
    QModbusTcpClient *m_6217 = nullptr;
    QModbusTcpClient *m_6224 = nullptr;
    QPointer<QModbusReply> m_6250PendingReply;
    QPointer<QModbusReply> m_6217PendingReply;
    QTimer *m_pollTimer = nullptr;
    int m_pollingIntervalMs = 1000;
    bool m_emergency = false;
    bool m_resetInProgress = false;
    quint64 m_resetSequence = 0;
    ResetStage m_resetStage = ResetStage::Idle;
};


#endif //TAIDAENVCONTROLAPP_MODBUSWORKER_H
