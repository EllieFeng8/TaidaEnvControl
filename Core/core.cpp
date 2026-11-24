//
// Created by aeyeo on 2026/11/23.
//

#include "core.h"

#include <QCoreApplication>
#include <QMetaProperty>
#include <QDebug>

Core& Core::instance()
{
    static Core inst; // 建立唯一的靜態實例
    return inst;      // 回傳該實例的引用
}

void Core::init(const QString &settingsFilePath, const ModbusConnectionSettings &connections)
{
    if (m_initialized) {
        return;
    }
    m_initialized = true;

    m_proxy = new TaidaEnvControlProxy(this);
    m_proxy->setEmergency(true);
    const QString filePath = settingsFilePath.isEmpty()
                                 ? QCoreApplication::applicationDirPath()
                                       + QStringLiteral("/device.ini")
                                 : settingsFilePath;
    m_settings = new QSettings(filePath, QSettings::IniFormat, this);
    loadSettings();

    const auto saveOnChange = [this] { saveSettings(); };
    connect(m_proxy, &TaidaEnvControlProxy::outPvChanged, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::inPvChanged, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::outSvChanged, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::inSvChanged, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::temp1Changed, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::temp2Changed, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::emergencyChanged, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::leak1Changed, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::leak2Changed, this, saveOnChange);
    connect(m_proxy, &TaidaEnvControlProxy::leak3Changed, this, saveOnChange);

    m_manager = new manager(connections, this);
    connect(m_manager, &manager::leakValuesChanged, this,
            [this](bool leak1, bool leak2, bool leak3) {
                m_proxy->setLeak1(leak1);
                m_proxy->setLeak2(leak2);
                m_proxy->setLeak3(leak3);
            });
    connect(m_manager, &manager::analogValuesChanged, this,
            [this](double temp1, double temp2, double inPv, double outPv) {
                m_proxy->setTemp1(temp1);
                m_proxy->setTemp2(temp2);
                m_proxy->setInPv(inPv);
                m_proxy->setOutPv(outPv);
            });
    connect(m_proxy,&TaidaEnvControlProxy::emergencyChanged,this,[this]() {
        m_manager->emergency(m_proxy->getEmergency());
    });
    connect(m_proxy,&TaidaEnvControlProxy::inSvChanged,this,[this]() {
        m_manager->setvalve(m_proxy->getInSv()*40.96);
    });
    connect(m_proxy,&TaidaEnvControlProxy::outSvChanged,this,[this]() {
        m_manager->setvalve2(m_proxy->getOutSv()*40.96);
    });
    connect(m_proxy,&TaidaEnvControlProxy::resetRequested,this,[this]() {
        m_manager->reset();
    });
    m_manager->emergency(true);
    saveSettings();
}

void Core::loadSettings()
{
    const QMetaObject *metaObject = m_proxy->metaObject();
    for (int i = metaObject->propertyOffset(); i < metaObject->propertyCount(); ++i) {
        const QMetaProperty property = metaObject->property(i);
        const QByteArray propertyName = property.name();
        if (propertyName == QByteArrayLiteral("emergency")
            || !m_settings->contains(QString::fromLatin1(propertyName))) {
            continue;
        }

        if (!property.write(m_proxy, m_settings->value(QString::fromLatin1(propertyName)))) {
            qWarning() << "Could not load setting:" << propertyName;
        }
    }

    m_settings->sync();
    if (m_settings->status() != QSettings::NoError) {
        qWarning() << "Could not read device.ini settings" << m_settings->status();
    }
}

void Core::saveSettings()
{
    if (!m_settings || !m_proxy) {
        return;
    }

    const QMetaObject *metaObject = m_proxy->metaObject();
    for (int i = metaObject->propertyOffset(); i < metaObject->propertyCount(); ++i) {
        const QMetaProperty property = metaObject->property(i);
        m_settings->setValue(QString::fromLatin1(property.name()), property.read(m_proxy));
    }

    m_settings->sync();
    if (m_settings->status() != QSettings::NoError) {
        qWarning() << "Could not write device.ini settings" << m_settings->status();
    }
}