import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2

WizardPage {
    id: root

    property string svName
    property string svUrl
    property string authorName
    property string authorUrl

    property string directory: ""

    signal goNextRequested()

    title: "Creating plugin"
    description: "Please wait..."
    goBackVisible: false
    goNextVisible: true
    finishVisible: false
    goNextEnabled: !busyIndicator.running

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: root.directory == ""
    }

    Component.onCompleted: {
        _streamingServices.createService(svName, svUrl, authorName, authorUrl)
    }

    Connections {
        target: _streamingServices
        onServiceCreated: {
            console.error("service created")
            root.directory = directory
            root.goNextRequested()
        }
    }
}