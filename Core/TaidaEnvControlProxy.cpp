#include "TaidaEnvControlProxy.h"

#include <cmath>

TaidaEnvControlProxy::TaidaEnvControlProxy(QObject *parent)
    : QObject(parent)
{
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
    emit emergencyChanged();
}

void TaidaEnvControlProxy::setLeak1(bool value)
{
    if (m_leak1 == value)
        return;
    m_leak1 = value;
    emit leak1Changed();
}

void TaidaEnvControlProxy::setLeak2(bool value)
{
    if (m_leak2 == value)
        return;
    m_leak2 = value;
    emit leak2Changed();
}

void TaidaEnvControlProxy::setLeak3(bool value)
{
    if (m_leak3 == value)
        return;
    m_leak3 = value;
    emit leak3Changed();
}

void TaidaEnvControlProxy::setReset()
{
    setOutSv(0);
    setInSv(0);
    emit resetRequested();
}
