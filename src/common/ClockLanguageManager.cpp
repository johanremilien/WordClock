/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the LGPL license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
#include "ClockLanguageManager.h"

#include <QDir>
#include <QFileInfo>

ClockLanguageManager::ClockLanguageManager(DeviceAccessBase *deviceAccess, QObject *parent)
    : ClockLanguageManagerBase{deviceAccess, parent}
{
    m_enabled = true;

    detectClockAvailableLocales();
}

void ClockLanguageManager::detectClockAvailableLocales()
{
    QFileInfoList wordClockLanguages = QDir(":/qml/languages").entryInfoList({"[^.]*.qml"});
    for (const auto &fileInfo : wordClockLanguages) {
        const QString baseName(fileInfo.baseName());
        if (baseName != QStringLiteral("Language")) {
            const QLocale locale(baseName);
            QString name = QLocale::languageToString(locale.language());
            if (baseName.split(QLatin1Char('_')).size() == 2)
                name.append(QStringLiteral(" (%1)").arg(locale.nativeCountryName()));
            m_clockAvailableLocales.insert(baseName, name);
        }
    }
}
