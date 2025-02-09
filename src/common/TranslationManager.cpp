/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the LGPL license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
#include "TranslationManager.h"

#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>

TranslationManager::TranslationManager(DeviceAccessBase *deviceAccess, QObject *parent)
    : TranslationManagerBase{deviceAccess, parent}
{
    m_enabled = true;

    getAvailableTransalations();
}

void TranslationManager::getAvailableTransalations()
{
    QFileInfoList applicationLanguages = QDir(":/i18n").entryInfoList({"*.qm"});
    m_availableTranslations.insert("en", "English");
    for (const auto &fileInfo : applicationLanguages) {
        const QString baseName(fileInfo.baseName().split(QLatin1Char('_'))[1]);
        m_availableTranslations.insert(baseName, QLocale::languageToString(QLocale(baseName).language()));
    }
}

void TranslationManager::switchLanguage(QString language)
{
    if (language != m_translator.language()) {
        qGuiApp->removeTranslator(&m_translator);
        //qGuiApp->removeTranslator(&m_translatorQt);
        if (m_availableTranslations.contains(language)) {
            if (m_translator.load(QLocale(language),
                                  QStringLiteral("wordclock"),
                                  QStringLiteral("_"),
                                  QStringLiteral(":/i18n")))
                qGuiApp->installTranslator(&m_translator);
            //http://code.qt.io/cgit/qt/qttranslations.git/tree/translations
            //if (m_translatorQt.load(QLocale(language),
            //                        QLatin1String("qtbase"),
            //                        QLatin1String("_"),
            //                        QLibraryInfo::location(QLibraryInfo::TranslationsPath)))
            //    qGuiApp->installTranslator(&m_translatorQt);
        }
        emit retranslate();
    }
}
