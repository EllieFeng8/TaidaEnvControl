#include "TaidaEnvControlProxy.h"

#include <cmath>
#include <QVariantMap>

TaidaEnvControlProxy::TaidaEnvControlProxy(QObject *parent)
    : QObject(parent)
{
}

QVariantList TaidaEnvControlProxy::getActiveAlarms() const
{
    QVariantList alarms;
    for (const auto &alarm : m_alarmHistory) {
        if (alarm.toMap().value("active").toBool())
            alarms.append(alarm);
    }
    return alarms;
}

void TaidaEnvControlProxy::setAlarmMarqueeEnabled(bool value)
{
    if (m_alarmMarqueeEnabled == value)
        return;
    m_alarmMarqueeEnabled = value;
    emit alarmMarqueeEnabledChanged();
}

void TaidaEnvControlProxy::recordAlarm(bool active, const QString &code,
                                      const QString &source, const QString &message)
{
    const auto now = QDateTime::currentDateTime();
    if (active) {
        m_alarmHistory.prepend(QVariantMap{{"code", code}, {"source", source},
                                          {"message", message}, {"occurredAt", now},
                                          {"clearedAt", QDateTime()}, {"active", true}});
    } else {
        // 只更新最近一筆尚未解除的同來源紀錄。
        for (auto &alarm : m_alarmHistory) {
            auto entry = alarm.toMap();
            if (entry.value("code").toString() == code && entry.value("active").toBool()) {
                entry.insert("active", false);
                entry.insert("clearedAt", now);
                alarm = entry;
                break;
            }
        }
    }
    emit alarmHistoryChanged();
    emit activeAlarmsChanged();
}

int TaidaEnvControlProxy::getActiveAlarmCount() const
{
    return int(m_emergency) + int(m_leak1) + int(m_leak2) + int(m_leak3);
}

void TaidaEnvControlProxy::setOutPv(double value)
{
    if (!std::isfinite(value))
        return;
    if (m_outPv == value)
        return;
    m_outPv = value;
    emit outPvChanged();
}

void TaidaEnvControlProxy::setInPv(double value)
{
    if (!std::isfinite(value))
        return;
    if (m_inPv == value)
        return;
    m_inPv = value;
    emit inPvChanged();
}

void TaidaEnvControlProxy::setOutSv(double value)
{
    if (!std::isfinite(value) || value < 0 || value > 100)
        return;
    value = std::round(value * 10) / 10;
    if (m_outSv == value)
        return;
    m_outSv = value;
    emit outSvChanged();
}

void TaidaEnvControlProxy::setInSv(double value)
{
    if (!std::isfinite(value) || value < 0 || value > 100)
        return;
    value = std::round(value * 10) / 10;
    if (m_inSv == value)
        return;
    m_inSv = value;
    emit inSvChanged();
}

void TaidaEnvControlProxy::setTemp1(double value)
{
    if (!std::isfinite(value))
        return;
    if (m_temp1 == value)
        return;
    m_temp1 = value;
    emit temp1Changed();
}

void TaidaEnvControlProxy::setTemp2(double value)
{
    if (!std::isfinite(value))
        return;
    if (m_temp2 == value)
        return;
    m_temp2 = value;
    emit temp2Changed();
}

void TaidaEnvControlProxy::setEmergency(bool value)
{
    if (m_emergency == value)
        return;
    m_emergency = value;
    recordAlarm(value, "EMERGENCY", tr("緊急開關"), tr("緊急開關已啟動，閥門設定已停用"));
    emit emergencyChanged();
}

void TaidaEnvControlProxy::setLeak1(bool value)
{
    if (m_leak1 == value)
        return;
    m_leak1 = value;
    recordAlarm(value, "LEAK_1", tr("機房"), tr("偵測到機房漏水"));
    emit leak1Changed();
}

void TaidaEnvControlProxy::setLeak2(bool value)
{
    if (m_leak2 == value)
        return;
    m_leak2 = value;
    recordAlarm(value, "LEAK_2", tr("管路"), tr("偵測到管路漏水"));
    emit leak2Changed();
}

void TaidaEnvControlProxy::setLeak3(bool value)
{
    if (m_leak3 == value)
        return;
    m_leak3 = value;
    recordAlarm(value, "LEAK_3", tr("閥箱"), tr("偵測到閥箱漏水"));
    emit leak3Changed();
}

void TaidaEnvControlProxy::setReset()
{
    setOutSv(0);
    setInSv(0);
    emit resetRequested();
}
