/**************************************************************************************************
**    Copyright (c) Kokleeko S.L. (https://github.com/kokleeko) and contributors.
**    All rights reserved.
**    Licensed under the MIT license. See LICENSE file in the project root for
**    details.
**    Author: Johan, Axel REMILIEN (https://github.com/johanremilien)
**************************************************************************************************/
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

import "qrc:/qml/controls" as Controls
import "qrc:/js/Helpers.js" as Helpers

Controls.Menu {
    function openUrl(url) {
        if (Helpers.isMobile)
            webView.openUrl(url)
        else
            Qt.openUrlExternally(url)
    }

    function greetings() {
        if (wordClock.is_AM)
            return QT_TR_NOOP("Good morning")
        else if (parseInt(wordClock.hours_value) < 18) // 6:00 PM
            return QT_TR_NOOP("Good afternoon")
        return QT_TR_NOOP("Good evening")
    }

    anchors.fill: parent  // @disable-check M16

    text: qsTr(greetings())
    footer: Controls.MenuSection {
        title.heading: headings.h3
        title.horizontalAlignment: Label.AlignHCenter
        title.text: "%1 %2 %3".arg(is_collapsed ? "☞" : "❤️")
        .arg(qsTr("Tip me")).arg(is_collapsed ? "☜" : "❤️")
        Layout.alignment: Qt.AlignBottom
        menuItems.flow: GridLayout.LeftToRight

        Controls.IconButton {
            name: "mug-saucer-solid"
            visible: !Helpers.isMobile
            tooltip: "Ko-fi"
            onClicked: openUrl("https://ko-fi.com/johanremilien")
        }
        Controls.IconButton {
            visible: Helpers.isMobile
            name: (Helpers.isIos ? "app-store-ios" : "google-play") + "-brands"
            tooltip: Helpers.isIos ? "App Store" : "Google Play"

            /*
             - latte    1.90
             - beer     2.95
             - fries    3.25
             - bone     3.50
             - burger   5.95
             - menu     8.45
             */
        }
    }

    Controls.MenuSection {
        visible: Helpers.isMobile //!Helpers.isWebAssembly  // @disable-check M16
        text: qsTr("Battery Saving")
        Controls.MenuItem {
            text: qsTr("Stay Awake")
            detailsComponent: Controls.Details {
                text: qsTr("\
If enabled the screen device will stay active, when the application is running.\
\nThink about activating '%1' if you might loose attention on your device.\
").arg(Helpers.isAndroid ? qsTr("App pinning") : qsTr("Guided Access"))
            }
            Switch {
                checked: !DeviceAccess.isAutoLockRequested
                onToggled: DeviceAccess.isAutoLockRequested = !checked
            }
        }
        Controls.MenuItem {
            text: qsTr("App pinning")
            visible: Helpers.isAndroid  // @disable-check M16
            Switch { onToggled: DeviceAccess.security(checked) }
        }
        Controls.MenuItem {
            text: "%1 (%2%)".arg(qsTr("Minimum Battery Level")).arg(control.value.toString())
            detailsComponent: Controls.Details {
                text: qsTr("\
'Stay Awake' feature will be automatically disabled when the battery level will reach this value,\
 unless the device is charging.") + (Helpers.isMobile ? "\n(%1: %2%)"
                                                        .arg(qsTr("current battery level"))
                                                        .arg(DeviceAccess.batteryLevel) : "")
            }
            Slider {
                from: 20
                to: 50
                stepSize: 5
                value: DeviceAccess.minimumBatteryLevel
                onMoved: DeviceAccess.minimumBatteryLevel = value
            }
        }
        Controls.MenuItem {
            text: "%1 (%2%)".arg(qsTr("Brightness Level")).arg(DeviceAccess.brightness)
            Slider {
                from: 0
                to: 100
                value: DeviceAccess.brightness
                onMoved: DeviceAccess.brightnessRequested = value/100
                Component.onCompleted: {
                    if (Helpers.isAndroid) {
                        DeviceAccess.requestBrightnessUpdate();
                    }
                }
            }
        }
    }

    Controls.MenuSection {
        text: qsTr("Appearance")
        Controls.MenuItem {
            text: qsTr("FullScreen")
            visible: !Helpers.isWebAssembly && !Helpers.isIos  // @disable-check M16
            Switch {
                checked: root.isFullScreen
                onToggled: Helpers.updateVisibility(root, DeviceAccess)
                Component.onCompleted: {
                    if (root.isFullScreen !== DeviceAccess.settingsValue("Appearance/fullScreen", false))
                        toggled()
                }
            }
        }
        Controls.MenuItem {
            text: qsTr("Display as widget")
            visible: Helpers.isDesktop  // @disable-check M16
            Switch {
                checked: root.isWidget
                onToggled: Helpers.updateDisplayMode(root)
                Component.onCompleted: {
                    if (root.isWidget !== DeviceAccess.settingsValue("Appearance/widget", false))
                        toggled()
                }
            }
        }
        Controls.MenuItem {
            visible: Helpers.isDesktop  // @disable-check M16
            enabled: !root.isFullScreen  // @disable-check M16
            text: "%1 (%2%)".arg(qsTr("Opacity")).arg(Math.floor(control.value))
            Slider {
                from: 10
                to: 100
                value: DeviceAccess.settingsValue("Appearance/opacity", 1) * 100
                onMoved: {
                    root.opacity = value/100
                    DeviceAccess.setSettingsValue("Appearance/opacity", root.opacity)
                }
            }
        }
        Controls.MenuItem {
            text: qsTr("Display as watermark")
            visible: Helpers.isDesktop  // @disable-check M16
            Button {
                text: "Activate"
                onClicked: {
                    root.visibility = Window.Maximized
                    root.opacity = Math.min(root.opacity, .85)
                    root.flags = (Qt.WindowStaysOnTopHint |
                                  Qt.WindowTransparentForInput |
                                  Qt.FramelessWindowHint)
                    settingPanel.close()
                }
            }
        }
        Controls.MenuItem {
            text: qsTr("Clock Language")
            Button { text: qsTr("Reset"); onClicked: wordClock.detectAndUseDeviceLanguage() }
            detailsComponent: ComboBox {
                palette.dark: systemPalette.text
                palette.text: systemPalette.text
                displayText: qsTr(currentText)
                currentIndex: Object.keys(wordClock.languages).indexOf(wordClock.selected_language)
                model: Object.values(wordClock.languages)
                onModelChanged: {
                    if (Helpers.isAndroid) {
                        currentIndex = Object.keys(wordClock.languages).indexOf(wordClock.selected_language)
                    }
                }
                onActivated: (index) => {
                                 const language = Object.keys(wordClock.languages)[index]
                                 wordClock.selectLanguage(language)
                                 DeviceAccess.setSettingsValue("Appearance/language", language)
                             }
            }
        }
        Controls.MenuItem {
            text: qsTr("Speech")
            Switch {
                checked: wordClock.enable_speech
                onToggled: DeviceAccess.setSettingsValue("Appearance/speech",
                                                         wordClock.enable_speech = checked)
            }
            detailsComponent:
                ComboBox {
                palette.dark: systemPalette.text
                palette.text: systemPalette.text
                displayText: qsTr(currentText)
                currentIndex: Object.keys(wordClock.speech_frequencies).indexOf(wordClock.speech_frequency)
                model: Object.values(wordClock.speech_frequencies)
                onActivated: (index) =>
                             {
                                 const speech_frequency = Object.keys(wordClock.speech_frequencies)[index]
                                 wordClock.speech_frequency = speech_frequency
                                 DeviceAccess.setSettingsValue("Appearance/speech_frequency", speech_frequency)
                             }
            }
        }
        Controls.MenuItem {
            text: qsTr("Voice")
            visible: !Helpers.isAndroid  // @disable-check M16
            detailsComponent:
                ComboBox {
                palette.dark: systemPalette.text
                palette.text: systemPalette.text
                function setSpeechVoice(index) {
                    DeviceAccess.setSpeechVoice(index)
                    if (wordClock.enable_speech) {
                        DeviceAccess.say(wordClock.written_time)
                    }
                    DeviceAccess.setSettingsValue("Appearance/%1_voice".arg(wordClock.selected_language), index)
                }

                model: Helpers.isAndroid ? [] : DeviceAccess.speechAvailableVoices[wordClock.selected_language]
                onModelChanged: {
                    currentIndex = DeviceAccess.settingsValue("Appearance/%1_voice".arg(wordClock.selected_language), 0)
                    DeviceAccess.setSpeechVoice(currentIndex)
                }
                onActivated: (index) => {
                                 DeviceAccess.setSpeechVoice(index)
                                 if (wordClock.enable_speech) {
                                     DeviceAccess.say(wordClock.written_time)
                                 }
                                 DeviceAccess.setSettingsValue("Appearance/%1_voice".arg(wordClock.selected_language), index)
                             }
            }
        }
        Controls.MenuItem {
            text: qsTr("Enable Special Message")
            detailsComponent: Controls.Details { text: qsTr("\
Each grid contains a special message that will be displayed instead of the time for a minute at the\
 following times 12:00 AM (00:00), 11:11 AM (11:11) and 10:22 PM (22:22).\n\nThe minute indicator at\
 the bottom of the panel will show 0, 1 or 2 lights, which will allow user to distinguish between\
 these different states.") }
            Switch {
                checked: wordClock.enable_special_message
                onToggled: DeviceAccess.setSettingsValue("Appearance/specialMessage",
                                                         wordClock.enable_special_message = checked)
            }
        }
        Controls.MenuItem {
            text: qsTr("Display tutorial as Startup")
            visible: !Helpers.isWebAssembly  // @disable-check M16
            Switch {
                checked: root.showTutorial
                onCheckedChanged: DeviceAccess.setSettingsValue("Tutorial/showPopup", checked)
            }
        }
    }
    Controls.MenuSection {
        function applyColors() {
            let bc  = DeviceAccess.settingsValue("Appearance/backgroundColor", "#000000")
            let alc = DeviceAccess.settingsValue("Appearance/activatedLetterColor", "#FF0000")
            let dlc = DeviceAccess.settingsValue("Appearance/deactivatedLetterColor", "#808080")
            backgroundColorPicker.extraControls[3].setColor(bc)
            activatedLetterColorPicker.extraControls[3].setColor(alc)
            deactivatedLetterColorPicker.extraControls[3].setColor(dlc)
        }
        visible: Helpers.isDesktop || Helpers.isWebAssembly  // @disable-check M16
        text: qsTr("Advanced")
        Component.onCompleted: wordClock.applyColors.connect(applyColors)
        Controls.MenuItem {
            id: backgroundColorPicker
            property color selected_color: extraControls[0].selected_color
            text: qsTr("Background Color")
            detailsComponent: Controls.Details { text: qsTr("\
The color can be set in HSL format (Hue, Saturation, Lightness) or in hexadecimal format ") }
            extras: [
                Controls.ColorPicker {},
                Controls.ColorFactorPicker {
                    hue: parent.children[0].hue
                    lightness: parent.children[0].lightness
                    factorType: Controls.Picker.Factors.Saturation
                    Component.onCompleted: {
                        onMoved.connect(() => parent.children[0].saturation = value)
                        moved()
                    }
                },
                Controls.ColorFactorPicker {
                    hue: parent.children[0].hue
                    saturation: parent.children[0].saturation
                    factorType: Controls.Picker.Factors.Lightness
                    Component.onCompleted: {
                        onMoved.connect(() => parent.children[0].lightness = value)
                        moved()
                    }
                },
                Controls.ColorHexField {
                    huePicker: parent.children[0]
                    saturationPicker: parent.children[1]
                    lightnessPicker: parent.children[2]
                }
            ]
            Component.onCompleted: {
                selected_colorChanged.
                connect(() => {
                            wordClock.background_color = selected_color
                            DeviceAccess.setSettingsValue("Appearance/backgroundColor",
                                                          selected_color.toString().toUpperCase())
                        })
            }
        }
        Controls.MenuItem {
            id: activatedLetterColorPicker
            property color selected_color: extraControls[0].selected_color
            text: qsTr("Activated Letter Color")
            extras: [
                Controls.ColorPicker {},
                Controls.ColorFactorPicker {
                    hue: parent.children[0].hue
                    lightness: parent.children[0].lightness
                    factorType: Controls.Picker.Factors.Saturation
                    Component.onCompleted: {
                        onMoved.connect(() => parent.children[0].saturation = value)
                        moved()
                    }
                },
                Controls.ColorFactorPicker {
                    hue: parent.children[0].hue
                    saturation: parent.children[0].saturation
                    factorType: Controls.Picker.Factors.Lightness
                    Component.onCompleted: {
                        onMoved.connect(() => parent.children[0].lightness = value)
                        moved()
                    }
                },
                Controls.ColorHexField {
                    huePicker: parent.children[0]
                    saturationPicker: parent.children[1]
                    lightnessPicker: parent.children[2]
                }
            ]
            Component.onCompleted: {
                selected_colorChanged.
                connect(() => {
                            wordClock.on_color = selected_color
                            DeviceAccess.setSettingsValue("Appearance/activatedLetterColor",
                                                          selected_color.toString().toUpperCase())
                        })
            }
        }
        Controls.MenuItem {
            id: deactivatedLetterColorPicker
            property color selected_color: extraControls[0].selected_color
            text: qsTr("Deactivated Letter Color")
            extras: [
                Controls.ColorPicker {},
                Controls.ColorFactorPicker {
                    hue: parent.children[0].hue
                    lightness: parent.children[0].lightness
                    factorType: Controls.Picker.Factors.Saturation
                    Component.onCompleted: {
                        onMoved.connect(() => parent.children[0].saturation = value)
                        moved()
                    }
                },
                Controls.ColorFactorPicker {
                    hue: parent.children[0].hue
                    saturation: parent.children[0].saturation
                    factorType: Controls.Picker.Factors.Lightness
                    Component.onCompleted: {
                        onMoved.connect(() => parent.children[0].lightness = value)
                        moved()
                    }
                },
                Controls.ColorHexField {
                    huePicker: parent.children[0]
                    saturationPicker: parent.children[1]
                    lightnessPicker: parent.children[2]
                }
            ]
            Component.onCompleted: {
                selected_colorChanged.
                connect(() => {
                            wordClock.off_color = selected_color
                            DeviceAccess.setSettingsValue("Appearance/deactivatedLetterColor",
                                                          selected_color.toString().toUpperCase())
                        })
            }
        }
        Controls.MenuItem {
            text: qsTr("Reset colors")
            Button {
                text: qsTr("Reset")
                onClicked: {
                    backgroundColorPicker.extraControls[3].setColor("#000000")
                    activatedLetterColorPicker.extraControls[3].setColor("#FF0000")
                    deactivatedLetterColorPicker.extraControls[3].setColor("#808080")
                }
            }
        }
    }

    Controls.MenuSection {
        text: qsTr("About")
        Controls.MenuItem {
            text: qsTr("Open source")
            detailsComponent: Controls.Details {
                text: qsTr("The source code is available on GitHub under the MIT license, see it")
            }
            Controls.IconButton {
                name: "github-brands"
                tooltip: "GitHub"
                onClicked: openUrl("https://github.com/kokleeko/WordClock")
            }
        }
        Controls.MenuItem {
            text: qsTr("Bug tracking")
            visible: false  // @disable-check M16
            detailsComponent: Controls.Details {
                text: qsTr("\
We anonymously track the appearance of bugs in Firebase in order to correct them almost as soon as \
you encounter them. But you can disable this feature to enter submarine mode.\
            ")
            }
            Switch  {
                checked: DeviceAccess.isBugTracking
                onToggled: DeviceAccess.isBugTracking = checked
            }
        }
        Controls.MenuItem {
            text: qsTr("Review")
            detailsComponent: Controls.Details { text: qsTr("Rate us by clicking on the stars") }
            Row {
                spacing: 5
                property int rating: DeviceAccess.settingsValue("About/rating", 0)

                Repeater {
                    model: 5
                    Button {
                        property bool isSelected: index <= parent.rating
                        icon.source: "qrc:/assets/star-%1.svg".arg(isSelected ? "solid" : "regular")
                        icon.color: systemPalette.windowText
                        display: Button.IconOnly
                        background: null
                        onClicked: {
                            DeviceAccess.setSettingsValue("About/rating",
                                                          parent.rating = index)
                            if (index >= 3)
                                DeviceAccess.requestReview()
                            else
                                badReviewPopup.open()
                        }
                    }
                }
            }
        }
        Controls.MenuItem {
            text: qsTr("Contact")
            detailsComponent: Controls.Details {
                text: qsTr("\
We would be very pleased to hear about your experience with this application")
            }
            extras: [
                Controls.IconButton {
                    name: "globe-solid"
                    visible: !Helpers.isWebAssembly
                    tooltip: qsTr("Web Site")
                    onClicked: openUrl("https://wordclock.kokleeko.io")
                },
                Controls.IconButton {
                    name: "app-store-ios-brands"
                    visible: !Helpers.isIos
                    tooltip: qsTr("App Store")
                    onClicked: openUrl("https://testflight.apple.com/join/02s6IwG2")
                },
                Controls.IconButton {
                    name: "twitter-brands"
                    tooltip: "Twitter"
                    onClicked: openUrl("https://twitter.com/kokleeko_io")
                },
                Controls.IconButton {
                    name: "instagram-brands"
                    tooltip: "Instagram"
                    onClicked: openUrl("https://instagram.com/kokleeko.io")
                },
                Controls.IconButton {
                    name: "youtube-brands"
                    tooltip: "YouTube"
                    onClicked: openUrl("https://youtube.com/channel/UCJ0QPsxjk_mxdIQtEZsIA6w")
                },
                Controls.IconButton {
                    name: "linkedin-brands"
                    tooltip: "LinkedIn"
                    onClicked: openUrl("https://www.linkedin.com/in/johanremilien")
                },
                Controls.IconButton {
                    name: "at-solid"
                    tooltip: qsTr("Email")
                    onClicked: Qt.openUrlExternally("mailto:contact@kokleeko.io")
                }
            ]
        }
        Controls.MenuItem {
            text: qsTr("Credits")
            detailsComponent: Controls.Details {
                text: qsTr("Developed with love by Johan Remilien and published by Denver.")
            }
            extras: [
                Button {
                    text: qsTr("Built with Qt")
                    onClicked: openUrl("https://www.qt.io")
                },
                Button {
                    text: qsTr("Icons from FontAwesome")
                    onClicked: openUrl("https://fontawesome.com")
                }
            ]
        }
        Item { implicitHeight: 25 }
    }
}
