//
// Created by aeyeo on 2026/11/23.
//

#ifndef TAIDAENVCONTROLAPP_CORE_H
#define TAIDAENVCONTROLAPP_CORE_H

#include <qobject.h>
#include <qqmlintegration.h>
#include <QSettings>
#include "TaidaEnvControlProxy.h"
#include "manager.h"
class Core : public QObject {
    Q_OBJECT
    QML_ELEMENT
public:
    static Core& instance();
    TaidaEnvControlProxy* m_proxy = nullptr;
    manager* m_manager = nullptr;
    void init(const QString &settingsFilePath = {},
              const ModbusConnectionSettings &connections = {});

private:
    void loadSettings();
    void saveSettings();

    QSettings *m_settings = nullptr;
    bool m_initialized = false;
};


#endif //TAIDAENVCONTROLAPP_CORE_H
