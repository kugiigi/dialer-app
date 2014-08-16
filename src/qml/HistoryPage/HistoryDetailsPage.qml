/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Telephony 0.1
import Ubuntu.Telephony.PhoneNumber 0.1 as PhoneUtils
import Ubuntu.Contacts 0.1
import QtContacts 5.0
import "dateUtils.js" as DateUtils

Page {
    id: historyDetailsPage
    objectName: "historyDetailsPage"
    anchors.fill: parent
    title: {
        if (contactWatcher.phoneNumber == "x-ofono-private") {
            return i18n.tr("Private number")
        } else if (contactWatcher.phoneNumber == "x-ofono-unknown") {
            return i18n.tr("Unknown number")
        } else if (contactWatcher.alias != "") {
            return contactWatcher.alias
        }
        return PhoneUtils.PhoneUtils.format(contactWatcher.phoneNumber)
    }

    property alias phoneNumber: contactWatcher.phoneNumber
    property string phoneNumberSubTypeLabel
    property variant events: null
    property QtObject eventModel: null

    Item {
        id: helper

        function updateSubTypeLabel() {
            var subLabel = contactWatcher.isUnknown
            if (phoneNumber) {
                var typeInfo = phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail))
                if (typeInfo) {
                    subLabel = typeInfo.label
                }
            }
            phoneNumberSubTypeLabel = subLabel
        }

        Component.onCompleted: updateSubTypeLabel()

        ContactWatcher {
            id: contactWatcher
            // FIXME: handle conf calls
            onPhoneNumberContextsChanged: helper.updateSubTypeLabel()
            onPhoneNumberSubTypesChanged: helper.updateSubTypeLabel()
            onIsUnknownChanged: helper.updateSubTypeLabel()
        }

        PhoneNumber {
            id: phoneDetail
            contexts: contactWatcher.phoneNumberContexts
            subTypes: contactWatcher.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
            Component.onCompleted: helper.updateSubTypeLabel()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.background
    }

    ListView {
        id: eventsView
        anchors.fill: parent
        model: events
        header: Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(12)

            Label {
                id: phoneLabel
                anchors {
                    top: parent.top
                    topMargin: units.gu(2)
                    left: parent.left
                    leftMargin: units.gu(2)
                }
                verticalAlignment: Text.AlignTop
                fontSize: "medium"
                text: PhoneUtils.PhoneUtils.format(contactWatcher.phoneNumber)
                elide: Text.ElideRight
                color: UbuntuColors.lightAubergine
                height: units.gu(2)
            }

            Label {
                id: phoneTypeLabel
                anchors {
                    top: phoneLabel.bottom
                    left: phoneLabel.left
                }
                text: historyDetailsPage.phoneNumberSubTypeLabel
                height: units.gu(2)
                verticalAlignment: Text.AlignVCenter
                fontSize: "small"
                visible: contactWatcher.interactive && !contactWatcher.isUnknown // non-interactive entries are calls from unknown or private numbers
            }

            Label {
                anchors {
                    left: phoneLabel.left
                    top: phoneTypeLabel.bottom

                }
                text: DateUtils.friendlyDay(events[0].date)
                height: units.gu(5)
                fontSize: "medium"
                verticalAlignment: Text.AlignVCenter
            }

            AbstractButton {
                id: messageButton
                anchors {
                    top: parent.top
                    topMargin: units.gu(1)
                    right: parent.right
                }
                width: units.gu(4)
                height: units.gu(4)

                Icon {
                    name: "message"
                    width: units.gu(2)
                    height: units.gu(2)
                    anchors.centerIn: parent
                }
            }

            AbstractButton {
                id: callButton
                anchors {
                    top: messageButton.top
                    right: messageButton.left
                }
                width: units.gu(4)
                height: units.gu(4)
                Icon {
                    name: "call-start"
                    width: units.gu(2)
                    height: units.gu(2)
                    anchors.centerIn: parent
                }
            }
        }

        delegate: ListItemWithActions {
            readonly property bool incoming: modelData.senderId !== "self"
            height: units.gu(5)
            anchors {
                left: parent.left
                right: parent.right
            }

            leftSideAction: Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered:  {
                    eventModel.removeEvent(modelData.accountId, modelData.threadId, modelData.eventId, modelData.type)
                }
            }

            Label {
                id: timeLabel
                // TRANSLATORS: HH:mm is the time format, translate it according to:
                // http://qt-project.org/doc/qt-4.8/qml-qt.html#formatDateTime-method
                text:Qt.formatTime(modelData.timestamp, i18n.tr("hh:mm"))
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                color: UbuntuColors.lightAubergine
                verticalAlignment: Qt.AlignVCenter
            }

            Label {
                id: durationLabel
                text: DateUtils.formatCallDuration(modelData.duration)
                anchors {
                    right: parent.right
                    top: parent.top
                    topMargin: units.gu(-1)
                }
                verticalAlignment: Text.AlignTop
                visible: !modelData.missed
                fontSize: "small"
                height: units.gu(2)
            }

            Label {
                id: typeLabel
                text: {
                    if (modelData.callMissed) {
                        return i18n.tr("Missed");
                    } else if (incoming) {
                        return i18n.tr("Incoming");
                    } else {
                        return i18n.tr("Outgoing");
                    }
                }
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: units.gu(-1)
                }
                verticalAlignment: Text.AlignBottom
                fontSize: "x-small"
            }
        }
    }

}
