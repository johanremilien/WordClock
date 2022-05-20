/**************************************************************************************************
**  Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**  All rights reserved.
**  Licensed under the MIT license. See LICENSE file in the project root for
**  details.
**  Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
import QtQuick 2.15
import QtQuick.Controls 2.15

import "../Helpers.js" as Helpers

TextField {
    function setColor(hexColor) {
        var color = Helpers.hexToHSL(hexColor)
        huePicker.value = color.hue
        huePicker.moved()
        saturationPicker.value = color.saturation
        saturationPicker.moved()
        lightnessPicker.value = color.lightness
        lightnessPicker.moved()
    }
    required property Picker huePicker
    required property Picker saturationPicker
    required property Picker lightnessPicker
    implicitWidth: 200
    text: huePicker.selectedColor.toString().toUpperCase()
    font.pointSize: Title.Headings.P1
    horizontalAlignment: TextField.AlignHCenter
    color: acceptableInput ? palette.text : "red"
    validator: RegExpValidator { regExp: /#(?:[0-9a-fA-F]{3}){1,2}$/ }
    Component.onCompleted: editingFinished.connect(()=>setColor(text))
}
