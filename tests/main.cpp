#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QQmlContext>

#include "../Core/TaidaEnvControlProxy.h"

class ProxyTestSetup : public QObject
{
    Q_OBJECT

public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        // 與正式程式使用同一個 C++ proxy，驗證實際 TC 綁定。
        engine->rootContext()->setContextProperty("TC", &m_proxy);
    }

private:
    TaidaEnvControlProxy m_proxy;
};

QUICK_TEST_MAIN_WITH_SETUP(TaidaEnvControl, ProxyTestSetup)

#include "main.moc"
