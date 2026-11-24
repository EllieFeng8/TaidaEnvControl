//
// Created by aeyeo on 2026/11/23.
//

#include "manager.h"

#include <QDebug>

manager::manager(const ModbusConnectionSettings &settings, QObject *parent)
    : QObject(parent)
{
    connect(&m_worker, &modbusWorker::readCompleted, this,
            [this](const QString &deviceName, const QModbusDataUnit &data) {
                if (deviceName == QStringLiteral("m_6250")) {
                    update6250value(data);
                } else if (deviceName == QStringLiteral("m_6217")) {
                    update6217value(data);
                }
            });
    connect(&m_worker, &modbusWorker::writeFailed, this,
            [](const QString &deviceName, const QString &error) {
                qWarning() << "Modbus write failed:" << deviceName << error;
            });
    connect(&m_worker, &modbusWorker::resetCompleted, this, [this] {
        qInfo() << "m_6250 reset completed";
        emit resetCompleted();
    });
    connect(&m_worker, &modbusWorker::resetFailed, this, [this](const QString &error) {
        qWarning() << "m_6250 reset failed:" << error;
        emit resetFailed(error);
    });
    m_worker.init(settings);
}

void manager::emergency(bool open) {
    m_emergency = open;
    m_worker.setEmergency(open);
}

void manager::reset()
{
    m_worker.reset();
}
void manager::setvalve(double value){
    if (m_emergency) {
        return;
    }
    m_worker.writeValveRegister(0, value);
}
void manager::setvalve2(double value){
    if (m_emergency) {
        return;
    }
    m_worker.writeValveRegister(1, value);
}

void manager::update6250value(const QModbusDataUnit &data){
    if (data.registerType() != QModbusDataUnit::Coils
        || data.startAddress() != 0 || data.valueCount() < 3) {
        qWarning() << "Unexpected m_6250 polling data";
        return;
    }
    emit leakValuesChanged(data.value(0) == 1, data.value(1) == 1, data.value(2) == 1);
}

void manager::update6217value(const QModbusDataUnit &data){
    if (data.registerType() != QModbusDataUnit::HoldingRegisters
        || data.startAddress() != 0 || data.valueCount() < 4) {
        qWarning() << "Unexpected m_6217 polling data";
        return;
    }
    const auto toPercent = [](quint16 value) {
        return static_cast<double>(value) * 100.0 / 65535.0;
    };
    emit analogValuesChanged(toPercent(data.value(0)), toPercent(data.value(1)),
                             toPercent(data.value(2)), toPercent(data.value(3)));
}