
import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtWebEngine 1.5
import QtWebChannel 1.0

import MellowPlayer 3.0

WebEngineView {
    id: root

    property QtObject service
    property QtObject player: service.player
    property var image: null
    property bool hasProprietaryCodecs: true
    property var userAgentSetting: _settings.get(SettingKey.PRIVACY_USER_AGENT)

    function updateImage() {
        root.grabToImage(function(result) {
            service.previewImageUrl = result.url;
            image = result;
        }, Qt.size(root.width, root.height));
    }

    function exitFullScreen() {
        root.triggerWebAction(WebEngineView.ExitFullScreen);
    }

    function zoomIn() {
        var nextZoomFactor = d.zoomFactorIndex + 1
        if (nextZoomFactor >= d.zoomFactors.length)
            nextZoomFactor = d.zoomFactorIndex;
        d.zoomFactorIndex = nextZoomFactor;
        zoomPane.show()
    }

    function zoomOut() {
        var previousZoomFactor = d.zoomFactorIndex - 1
        if (previousZoomFactor < 0)
            previousZoomFactor = 0
        d.zoomFactorIndex = previousZoomFactor;
        zoomPane.show()
    }

    function resetZoom() {
        d.zoomFactorIndex = d.resetZoomFactorIndex;
        zoomPane.show()
    }

    enabled: visible
    url: service.url
    visible: _streamingServices.currentService && _streamingServices.currentService.name === service.name
    profile {
        httpUserAgent: userAgentSetting.value
    }
    settings {
        pluginsEnabled : true
        fullScreenSupportEnabled: true
        autoLoadImages: true
        javascriptEnabled: true
        errorPageEnabled: true
        autoLoadIconsForPage: true
    }
    userScripts: d.getUserScripts()
    zoomFactor: d.zoomFactors[d.zoomFactorIndex]
    webChannel: webChannel

    onContextMenuRequested: {
        request.accepted = true;
        contextMenu.x = request.x;
        contextMenu.y = request.y;
        contextMenu.canCopy = request.selectedText !== "";
        contextMenu.canPaste = request.isContentEditable && _clipboard.canPaste();
        contextMenu.canUnselect = request.selectedText !== "";
        contextMenu.canGoBack = root.canGoBack;
        contextMenu.canGoForward = root.canGoForward;
        contextMenu.hasLink = request.linkText !== "";
        contextMenu.show();
    }
    onAuthenticationDialogRequested: function(request) {
        request.accepted = true;
        Dialogs.open("Authentication.qml", mainWindow, {"request": request});
    }
    onJavaScriptDialogRequested: function(request){
        var component = "";
        switch (request.type) {
            case JavaScriptDialogRequest.DialogTypeAlert:
                component = "Alert.qml"
                break;
            case JavaScriptDialogRequest.DialogTypeConfirm:
                component = "Confirmation.qml"
                break;
            case JavaScriptDialogRequest.DialogTypePrompt:
                component = "Prompt.qml"
                break;
            case JavaScriptDialogRequest.DialogTypeUnload:
            default:
                component = "Reload.qml"
                break;
        }
        Dialogs.open(component, mainWindow, {"request": request});
        request.accepted = true;
    }
    onFormValidationMessageRequested: function(request) {
        switch (request.type) {
            case FormValidationMessageRequest.Show:
                request.accepted = true;
                validationMessage.text = request.text;
                validationMessage.x = request.anchor.x
                validationMessage.y = request.anchor.y + request.anchor.height;
                validationMessage.visible = true;
                break;
            case FormValidationMessageRequest.Move:
                break;
            case FormValidationMessageRequest.Hide:
                validationMessage.visible = false;
                break;
        }
    }
    onLoadingChanged: {
        if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
            updateImage();
        }
        else
            d.checkForCustomUrlRequired();
    }
    onFullScreenRequested: mainWindow.toggleFullScreen(request)
    onNewViewRequested: mainWindow.openWebPopup(request, profile)

    ValidationMessage {
        id: validationMessage
    }

    QtObject {
        id: playerBridge

        property var updateResults
        property bool isRunning: root.visible

        signal play()
        signal pause()
        signal next()
        signal previous()
        signal addToFavorites()
        signal removeFromFavorites()
        signal seekToPosition(var position)
        signal changeVolume(double newVolume)

        onUpdateResultsChanged: root.player.setUpdateResults(updateResults);

        WebChannel.id: "player"
    }

    WebChannel {
        id: webChannel
        registeredObjects: [playerBridge]
    }

    CustomUrlPane {
        id: customUrlPane

        customUrl: service.url
        x: root.width / 2 - width / 2; y: -2; z: 1
        width: 500

        onReloadRequested: root.reload()        
        onCustomUrlChanged: {
            if (customUrl !== service.url) {
                service.url = customUrl
                start()
            }
        }
    }

    Pane {
        id: zoomPane

        anchors { top: parent.top; right: parent.right; margins: 2 }
        leftPadding: 6
        rightPadding: 6
        bottomPadding: 3
        topPadding: 3
        z: 1
        visible: false

        function show() {
            visible = true;
            hideTimer.running = true;
            hideTimer.restart();
        }

        Material.background: _theme.primary
        Material.foreground: _theme.primaryForeground
        Material.elevation: 2
        Material.theme: _theme.isDark(_theme.primary) ? Material.Dark : Material.Light

        RowLayout {
            spacing: 8

            IconToolButton {
                iconChar: MaterialIcons.icon_remove
                iconSize: 16
                tooltip: qsTr("Zoom out")

                onTriggered: root.zoomOut()
            }

            Label {
                text: Math.round(root.zoomFactor * 100) + "%"
                opacity: 0.8
            }

            IconToolButton {
                iconChar: MaterialIcons.icon_add
                iconSize: 16
                tooltip: qsTr("Zoom in")

                onTriggered: root.zoomIn()
            }

            ToolButton {
                text: qsTr("Reset")

                onClicked: root.resetZoom()
            }
        }

        Timer {
            id: hideTimer

            interval: 2000
            onTriggered: zoomPane.visible = false
        }
    }

    WebViewContextMenu {
        id: contextMenu

        onCopyRequested: root.triggerWebAction(WebEngineView.Copy)
        onPasteRequested: root.triggerWebAction(WebEngineView.Paste)
        onUnselectRequested: root.triggerWebAction(WebEngineView.Unselect)

        onCopyLinkRequested: root.triggerWebAction(WebEngineView.CopyLinkToClipboard)
        onOpenLinkRequested: root.triggerWebAction(WebEngineView.OpenLinkInNewTab)

        onGoBackRequested: root.goBack()
        onGoForwardRequested: root.goForward()
        onReloadRequested: root.reload()
        onViewPageSourceRequested: root.triggerWebAction(WebEngineView.ViewSource)
    }

    Connections {
        target: userAgentSetting
        onValueChanged: { console.warn("new user agent: " + userAgentSetting.value); reload(); }
    }

    Connections {
        target: service.networkProxy
        onChanged: reload()
    }

    Connections {
        target: root.player

        onPlay: playerBridge.play()
        onPause: playerBridge.pause()
        onNext: playerBridge.next()
        onPrevious: playerBridge.previous()
        onAddToFavorites: playerBridge.addToFavorites()
        onRemoveFromFavorites: playerBridge.removeFromFavorites()
        onSeekToPositionRequest: playerBridge.seekToPosition(newPosition)
        onChangeVolumeRequest: playerBridge.changeVolume(newVolume)
    }

    QtObject {
        id: d

        property var zoomFactors: [0.25, 0.33, 0.5, 0.67, 0.75, 0.8, 0.9, 1, 1.1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5]
        property int resetZoomFactorIndex: 7
        property int zoomFactorIndex: root.service.zoomFactor

        onZoomFactorIndexChanged: root.service.zoomFactor = zoomFactorIndex

        function checkForCustomUrlRequired() {
            var match = service.url.match("(@.*@)");
            if (match !== null) {
                customUrlPane.open()
            }
        }

        function checkForProprietaryCodecs() {
            runJavaScript("var a = document.createElement('audio'); !!(a.canPlayType && a.canPlayType('audio/mpeg;').replace(/no/, ''));", function(result) {
                hasProprietaryCodecs = result;
            })
        }

        function getUserScripts() {
            var scripts = [];

            var webChannelScript = createMellowPlayerScriptFromSourceUrl("WebChannelAPI", "qrc:///qtwebchannel/qwebchannel.js");
            webChannelScript.injectionPoint = WebEngineScript.DocumentCreation;
            scripts.push(webChannelScript);
            scripts.push(createMellowPlayerScriptFromSourceUrl("MellowPlayerAPI", "qrc:/MellowPlayer/Presentation/Resources/mellowplayer.js"));
            scripts.push(createMellowPlayerScriptFromSourceCode("IntegrationPlugin", root.service.sourceCode));

            for (var i = 0; i < service.userScripts.model.count; i++) {
                var userScript = service.userScripts.model.get(i);
                scripts.push(createUserScriptFromCode(userScript.name, userScript.code));
            }

            reload();

            return scripts;
        }

        function createUserScriptFromCode(name, sourceCode) {
            var webEngineScript = Qt.createQmlObject("import QtWebEngine 1.5; WebEngineScript {}", root, "webEngineScript.js");
            webEngineScript.name = name;
            webEngineScript.sourceCode = sourceCode;
            webEngineScript.injectionPoint = WebEngineScript.DocumentReady;
            return webEngineScript;
        }

        function createMellowPlayerScript(name) {
            var webEngineScript = Qt.createQmlObject("import QtWebEngine 1.5; WebEngineScript {}", root, "webEngineScript.js");
            webEngineScript.name = name;
            webEngineScript.injectionPoint = WebEngineScript.DocumentReady;
            webEngineScript.worldId = WebEngineScript.MainWorld;
            return webEngineScript;
        }

        function createMellowPlayerScriptFromSourceUrl(name, sourceUrl) {
            var webEngineScript = createMellowPlayerScript(name)
            webEngineScript.sourceUrl = sourceUrl;
            return webEngineScript;
        }

        function createMellowPlayerScriptFromSourceCode(name, sourceCode) {
            var webEngineScript = createMellowPlayerScript(name)
            webEngineScript.sourceCode = sourceCode;
            return webEngineScript;
        }
    }

//    QtObject {
//        id: nullService

//        property int zoomFactor: 1
//        property QtObject player: QtObject {
//            property string sourceCode: ""

//            signal play()
//            signal pause()
//            signal next()
//            signal previous()
//            signal addToFavorites()
//            signal removeFromFavorites()
//            signal seekToPositionRequest(var position)
//            signal changeVolumeRequest(double newVolume)
//        }

//        property QtObject networkProxy: QtObject {
//            signal changed();
//        }
//        property QtObject userScripts: QtObject {
//            property var model: []
//        }

//        property string url: ""
//        property string name: ""
//    }
}
