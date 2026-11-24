//
// Created by aeyeo on 2026/11/23.
//

#ifndef TAIDAENVCONTROLAPP_MANAGER_H
#define TAIDAENVCONTROLAPP_MANAGER_H
#include <QObject>
#include "TaidaEnvControlProxy.h"
#include "modbusWorker.h"

class manager : public QObject {
    Q_OBJECT
public:
    explicit manager(const ModbusConnectionSettings &settings = {}, QObject *parent = nullptr);
public slots:
    //UI to device
    void reset();
    void emergency(bool open);
    void setvalve(double value);
    void setvalve2(double value);

    //device to UI
    void update6250value(const QModbusDataUnit &data);
    void update6217value(const QModbusDataUnit &data);

signals:
    void leakValuesChanged(bool leak1, bool leak2, bool leak3);
    void analogValuesChanged(double temp1, double temp2, double inPv, double outPv);
    void resetCompleted();
    void resetFailed(const QString &error);

private:
    modbusWorker m_worker;
    bool m_emergency = false;
};


#endif //TAIDAENVCONTROLAPP_MANAGER_H
