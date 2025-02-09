/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the LGPL license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
#include "ScreenBrightnessManagerBase.h"

template<>
QString ManagerBase<ScreenBrightnessManagerBase>::m_name{QStringLiteral("screenBrightness")};

ScreenBrightnessManagerBase::ScreenBrightnessManagerBase(DeviceAccessBase *deviceAccess,
                                                         QObject *parent)
    : ManagerBase(deviceAccess, parent)
{}

void ScreenBrightnessManagerBase::updateBrightness(float brightness)
{
    m_brightness = qRound(brightness * 100);
    qCDebug(lc) << "[R] brightness:" << m_brightness;
    emit brightnessChanged();
}
