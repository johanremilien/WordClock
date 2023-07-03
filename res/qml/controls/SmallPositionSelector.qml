/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the LGPL license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import DeviceAccess 1.0

import "qrc:/js/Helpers.js" as HelpersJS

PositionSelector {
    delegate:
        Frame {
        readonly property int buttonIndex: index
        readonly property string text: qsTranslate("PositionSelector", modelData) + DeviceAccess.managers.translation.emptyString
        Layout.fillHeight: true
        Layout.fillWidth: true
        contentItem: ColumnLayout {
            Layout.fillWidth: true
            Text {
                color: (index === 2 && parent.parent.checked) ? palette.brightText : palette.buttonText
                text: parent.parent.text
                Layout.alignment: Qt.AlignCenter
            }
            Flow {
                width: parent.parent.parent.width
                Repeater {
                    model: [ QT_TR_NOOP("Left"), QT_TR_NOOP("Center"), QT_TR_NOOP("Right") ]
                    RadioButton {
                        readonly property int positionIndex: index + 3 * buttonIndex
                        enabled: HelpersJS.isWeaklyEqual(wordClock.accessories[positionIndex], "", name)
                        text: qsTr(modelData) + DeviceAccess.managers.translation.emptyString
                        checked: wordClock.accessories[positionIndex] === name
                        ButtonGroup.group: radioGroup
                        onClicked: activate(positionIndex)
                    }
                }
            }
        }
    }
}
