/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the LGPL license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
#include "PersistenceManager.h"

#include <QFile>
#include <QTimerEvent>

#ifdef Q_OS_WASM
#include <emscripten.h>
#endif

PersistenceManager::PersistenceManager(DeviceAccessBase *deviceAccess, QObject *parent)
    : PersistenceManagerBase{deviceAccess, parent}
{
    m_enabled = true;
    startTimer(0);
}

QVariant PersistenceManager::value(QString key, QVariant defaultValue) const
{
    QVariant value = m_settings.value(key, defaultValue);
    if (value.type() == QVariant::String && value.toString() == "false")
        return QVariant::fromValue(false);
    return m_settings.value(key, defaultValue);
}

void PersistenceManager::setValue(QString key, QVariant value)
{
    m_settings.setValue(key, value);
}

void PersistenceManager::timerEvent(QTimerEvent *event)
{
    if (m_settings.status() != QSettings::AccessError) {
        killTimer(event->timerId());
        qCDebug(lc) << "settings ready";
        emit settingsReady();
    }
}

void PersistenceManager::clear()
{
    m_settings.clear();
}

void PersistenceManager::printAll()
{
    const QStringList &allKeys = m_settings.allKeys();
    qCDebug(lc) << m_settings.fileName() << allKeys.size();
    for (const auto &key : allKeys)
        qCDebug(lc) << __func__
                    << QStringLiteral("%1: %2").arg(key, m_settings.value(key).toString());
}

void PersistenceManager::processAtSettingsReady()
{
    PersistenceManagerBase::processAtSettingsReady();
#ifdef Q_OS_WASM
    EM_ASM({
        document.querySelector('#qtspinner').style.display = 'none';
        document.querySelector('#qtcanvas').style.display = 'block';
    });
#endif
    QString previousVersionName = m_settings.value("Application/versionName").toString();
    if (previousVersionName != VERSION) {
        const QStringList &childGroups = m_settings.childGroups();
        for (const auto &group : childGroups) {
            if (group != QStringLiteral("Colors")) {
                m_settings.beginGroup(group);
                m_settings.remove("");
                m_settings.endGroup();
            }
        }
        m_settings.setValue("Application/versionName", VERSION);
    }
}
