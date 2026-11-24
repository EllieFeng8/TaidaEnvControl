#pragma once

#include <QObject>
#include <QDateTime>
#include <QVariantList>

// UI 共用資料入口，QML 以 TC 存取，例如 TC.outPv、TC.outSv。
// READ 使用 get、WRITE 使用 set、NOTIFY 使用 Changed；只有值改變才通知。
class TaidaEnvControlProxy : public QObject
{
    Q_OBJECT

    // 目前異常，依發生時間由新至舊排列；解除後自動移除。
    Q_PROPERTY(QVariantList activeAlarms READ getActiveAlarms NOTIFY activeAlarmsChanged)
    Q_PROPERTY(int activeAlarmCount READ getActiveAlarmCount NOTIFY activeAlarmsChanged)
    Q_PROPERTY(QVariantList alarmHistory READ getAlarmHistory NOTIFY alarmHistoryChanged)
    // 異常跑馬燈顯示開關，預設 true；仍須有未解除異常才顯示。
    // 只控制內容顯示，不影響異常紀錄或設備狀態；內容沿用 activeAlarms。
    Q_PROPERTY(bool alarmMarqueeEnabled READ getAlarmMarqueeEnabled WRITE setAlarmMarqueeEnabled NOTIFY alarmMarqueeEnabledChanged)

    // 出水閥目前開度（%）。
    Q_PROPERTY(double outPv READ getOutPv WRITE setOutPv NOTIFY outPvChanged)
    // 入水閥目前開度（%）。
    Q_PROPERTY(double inPv READ getInPv WRITE setInPv NOTIFY inPvChanged)
    // 出水閥設定開度（0–100%，一位小數）。
    Q_PROPERTY(double outSv READ getOutSv WRITE setOutSv NOTIFY outSvChanged)
    // 入水閥設定開度（0–100%，一位小數）。
    Q_PROPERTY(double inSv READ getInSv WRITE setInSv NOTIFY inSvChanged)
    // 溫度監控 1（°C）。
    Q_PROPERTY(double temp1 READ getTemp1 WRITE setTemp1 NOTIFY temp1Changed)
    // 溫度監控 2（°C）。
    Q_PROPERTY(double temp2 READ getTemp2 WRITE setTemp2 NOTIFY temp2Changed)
    // 緊急開關：true 啟動，禁用 UI 閥門設定。
    Q_PROPERTY(bool emergency READ getEmergency WRITE setEmergency NOTIFY emergencyChanged)
    // 機房漏水：true 表示漏水。
    Q_PROPERTY(bool leak1 READ getLeak1 WRITE setLeak1 NOTIFY leak1Changed)
    // 管路漏水：true 表示漏水。
    Q_PROPERTY(bool leak2 READ getLeak2 WRITE setLeak2 NOTIFY leak2Changed)
    // 閥箱漏水：true 表示漏水。
    Q_PROPERTY(bool leak3 READ getLeak3 WRITE setLeak3 NOTIFY leak3Changed)

public:
    explicit TaidaEnvControlProxy(QObject *parent = nullptr);

    QVariantList getActiveAlarms() const;
    int getActiveAlarmCount() const;
    QVariantList getAlarmHistory() const { return m_alarmHistory; }
    // QML 使用 TC.alarmMarqueeEnabled；C++ 使用此 getter/setter 控制顯示。
    bool getAlarmMarqueeEnabled() const { return m_alarmMarqueeEnabled; }
    void setAlarmMarqueeEnabled(bool value);

    // 出水閥目前開度（%）。
    double getOutPv() const { return m_outPv; }
    void setOutPv(double value);

    // 入水閥目前開度（%）。
    double getInPv() const { return m_inPv; }
    void setInPv(double value);

    // 出水閥設定開度（0–100%，一位小數）。
    double getOutSv() const { return m_outSv; }
    void setOutSv(double value);

    // 入水閥設定開度（0–100%，一位小數）。
    double getInSv() const { return m_inSv; }
    void setInSv(double value);

    // 溫度監控 1（°C）。
    double getTemp1() const { return m_temp1; }
    void setTemp1(double value);

    // 溫度監控 2（°C）。
    double getTemp2() const { return m_temp2; }
    void setTemp2(double value);

    // 緊急開關：true 啟動，禁用 UI 閥門設定。
    bool getEmergency() const { return m_emergency; }
    void setEmergency(bool value);

    // 機房漏水：true 表示漏水。
    bool getLeak1() const { return m_leak1; }
    void setLeak1(bool value);

    // 管路漏水：true 表示漏水。
    bool getLeak2() const { return m_leak2; }
    void setLeak2(bool value);

    // 閥箱漏水：true 表示漏水。
    bool getLeak3() const { return m_leak3; }
    void setLeak3(bool value);

    // 確認重置後呼叫 TC.setReset()：歸零 SV 並送出設備重啟請求。
    // 每次呼叫都通知，不清除設備讀值、急停或漏水狀態。
    Q_INVOKABLE void setReset();

signals:
    void alarmMarqueeEnabledChanged(); // 跑馬燈開關改變時通知，重複設定不通知。
    void alarmHistoryChanged();
    void activeAlarmsChanged();
    void outPvChanged();
    void inPvChanged();
    void outSvChanged();
    void inSvChanged();
    void temp1Changed();
    void temp2Changed();
    void emergencyChanged();
    void leak1Changed();
    void leak2Changed();
    void leak3Changed();
    void resetRequested(); // 設備後端連接此訊號執行實際重啟。

private:
    void recordAlarm(bool active, const QString &code, const QString &source, const QString &message);
    QVariantList m_alarmHistory;
    bool m_alarmMarqueeEnabled = true;
    double m_outPv = 0;
    double m_inPv = 0;
    double m_outSv = 0;
    double m_inSv = 0;
    double m_temp1 = 0;
    double m_temp2 = 0;
    bool m_emergency = false;
    bool m_leak1 = false;
    bool m_leak2 = false;
    bool m_leak3 = false;
};
