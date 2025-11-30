import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.components as WorkspaceComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.extras as PlasmaExtras

import Qt.labs.platform as Platforms

import "../../assets/emoji-icons.js" as EmojiIcons

Kirigami.ScrollablePage {
    id: displayConfigPage

    // =========================================================================
    // Properties & Helper Functions
    // =========================================================================

    property string smallSizeEmojiLabel: qsTr("Small")
    property string largeSizeEmojiLabel: qsTr("Large")
    property var emojiIconPool: EmojiIcons.iconEmojis || []

    function emojiFontPixelSize(gridSize) {
        const size = gridSize || 0
        const scaled = Math.floor(size * 0.7)
        return scaled > 0 ? scaled : 16
    }

    function _randomEmojiFromPool() {
        if (!emojiIconPool || emojiIconPool.length === 0) {
            return null
        }
        return emojiIconPool[Math.floor(Math.random() * emojiIconPool.length)]
    }

    function rollSizeEmojiLabels() {
        const emoji = _randomEmojiFromPool()

        if (emoji) {
            smallSizeEmojiLabel = emoji
            largeSizeEmojiLabel = emoji
        } else {
            smallSizeEmojiLabel = qsTr("Small")
            largeSizeEmojiLabel = qsTr("Large")
        }
    }

    Component.onCompleted: {
        rollSizeEmojiLabels()
    }

    // =========================================================================
    // Visual Layout
    // =========================================================================

    ColumnLayout {
        Kirigami.FormLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing

            // --- Display Section ---

            Kirigami.FormLayout {
                wideMode: false
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: "Display"
                }
            }

            // Grid size slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                PlasmaComponents.Label {
                    text: smallSizeEmojiLabel
                    font.pixelSize: emojiFontPixelSize(gridSizeSlider.sizeValues[0])
                }

                PlasmaComponents.Slider {
                    id: gridSizeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 2
                    stepSize: 1

                    property var sizeValues: [36, 44, 56]
                    property var sizeLabels: ["Small", "Medium", "Large"]

                    value: {
                        const currentSize = plasmoid.configuration.GridSize
                        if (currentSize <= 36) return 0
                            if (currentSize <= 44) return 1
                                return 2
                    }

                    onValueChanged: {
                        plasmoid.configuration.GridSize = sizeValues[value]
                    }

                    Component.onCompleted: {
                        // Set initial value based on configuration
                        const configSize = plasmoid.configuration.GridSize
                        if (configSize <= 36) value = 0
                            else if (configSize <= 44) value = 1
                                else value = 2
                    }
                }

                PlasmaComponents.Label {
                    text: largeSizeEmojiLabel
                    font.pixelSize: emojiFontPixelSize(gridSizeSlider.sizeValues[2])
                }
            }

            // --- Behavior Section ---

            Kirigami.FormLayout {
                wideMode: false
                Kirigami.Separator {
                    Kirigami.FormData.isSection: true
                    Kirigami.FormData.label: "Behavior"
                }
            }

            // Close after selection checkbox
            PlasmaComponents.CheckBox {
                text: i18n("Close popup after emoji selection")
                checked: plasmoid.configuration.CloseAfterSelection
                onCheckedChanged: plasmoid.configuration.CloseAfterSelection = checked
            }

            // Keyboard navigation checkbox
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                PlasmaComponents.CheckBox {
                    text: i18n("Enable keyboard navigation")
                    checked: plasmoid.configuration.KeyboardNavigation
                    onCheckedChanged: plasmoid.configuration.KeyboardNavigation = checked
                    Layout.alignment: Qt.AlignVCenter
                }

                PlasmaComponents.ToolButton {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium

                    icon.name: "help-hint-symbolic"

                    PlasmaComponents.ToolTip {
                        text: "← ↑ → ↓: Navigate ui elements\nENTER: Copy emoji/s\nSHIFT+ENTER: Copy emoji/s name\nCTRL+ENTER: Select emoji/s\nTAB: Focus next element\nSHIFT+TAB: Focus previous element\nESC: Close popup"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        cursorShape: Qt.WhatsThisCursor

                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }

        // --- Sync Section ---

        // Sync emoji database button
        PlasmaComponents.Button {
            id: syncEmojiButton
            // Always show the model's status text; disable during sync
            text: syncEmojiModel.statusText
            enabled: !syncEmojiModel.isSyncing
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            onClicked: {
                syncEmojiModel.startSync()
            }
        }

        // Log display area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: PlasmaCore.Theme.backgroundColor
            border.color: PlasmaCore.Theme.textColor
            border.width: 1
            radius: 4
            visible: syncEmojiModel.logVisible

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4

                TextArea {
                    id: syncLogArea
                    text: syncEmojiModel.logText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    font.family: "monospace"
                    font.pixelSize: 10
                    selectByMouse: true
                }
            }
        }
    }

    // =========================================================================
    // Logic Models & DataSources
    // =========================================================================

    QtObject {
        id: syncEmojiModel

        property bool isSyncing: false
        property bool networkError: false
        property string statusText: i18n("Sync emoji database from Unicode")
        property var activeDataSource: null
        property string statusFile: ""
        property bool logVisible: false
        property string logText: ""
        property int pollIntervalMs: 1000
        property int lastLogSize: 0

        function addLog(message) {
            var timestamp = new Date().toLocaleTimeString();
            logText += "[" + timestamp + "] " + message + "\n";
        }

        function clearLog() {
            logText = "";
        }

        function startSync() {
            if (isSyncing) return

                // Stop all timers first to ensure clean state
                syncPollTimer.stop()
                resetStatusTimer.stop()

                isSyncing = true
                networkError = false
                statusText = i18n("Syncing...")
                logVisible = true
                clearLog()
                addLog("Starting emoji database sync...")
                pollIntervalMs = 1000
                lastLogSize = 0

                // Remove previous run's temp log file to avoid accumulation
                if (statusFile && statusFile.length > 0) {
                    var cleanupDS = Qt.createQmlObject(
                        "import org.kde.plasma.plasma5support as Plasma5Support; Plasma5Support.DataSource { engine: 'executable'; connectedSources: [] }",
                        syncEmojiModel
                    );
                    cleanupDS.connectSource('rm -f "' + statusFile + '"');
                    Qt.callLater(function() {
                        cleanupDS.destroy();
                    });
                    statusFile = "";
                }

                // Execute the update script using Qt's system call
                executeUpdateScript()
                // Start polling timer to check status
                syncPollTimer.interval = pollIntervalMs
                syncPollTimer.start()
        }

        function executeUpdateScript() {
            var scriptPath = Qt.resolvedUrl('../../service/update_emoji.sh')
            var cleanScriptPath = scriptPath.toString().replace('file://', '').replace(/\/\//g, '/');

            console.log('Executing sync script: ' + cleanScriptPath);
            addLog('Executing sync script: ' + cleanScriptPath);

            var timestamp = Date.now();
            statusFile = "/tmp/emoji_sync_" + timestamp + ".log";
            addLog('Log file: ' + statusFile);

            // Run script and redirect output
            var cmd = 'bash "' + cleanScriptPath + '" > "' + statusFile + '" 2>&1; echo "EXIT:$?" >> "' + statusFile + '"';
            console.log('Command: ' + cmd);
            addLog('Command: ' + cmd);

            try {
                var executableDS = Qt.createQmlObject(`
                import QtQuick
                import org.kde.plasma.plasma5support as Plasma5Support

                Plasma5Support.DataSource {
                    engine: 'executable'
                    connectedSources: []

                    onNewData: function(sourceName, data) {
                        console.log('Script execution initiated');
                        syncEmojiModel.addLog('Script execution initiated');
                        // Start polling immediately
                        syncPollTimer.start();
                        disconnectSource(sourceName);
                        Qt.callLater(function() { destroy(); });
                    }
                }
                `, syncEmojiButton);

                executableDS.connectSource(cmd);
                syncEmojiModel.activeDataSource = executableDS;
                addLog('Command execution started');

            } catch (error) {
                console.error('Error starting sync: ' + error);
                addLog('Error starting sync: ' + error);
                onSyncError();
            }
        }

        function checkSyncStatus() {
            if (!isSyncing || !statusFile) return;

            var readCmd = 'cat "' + statusFile + '" 2>/dev/null';

            var reader = Qt.createQmlObject(`
            import QtQuick
            import org.kde.plasma.plasma5support as Plasma5Support

            Plasma5Support.DataSource {
                engine: 'executable'
                connectedSources: []

                onNewData: function (sourceName, data) {
                    var output = data['stdout'] || '';

                    // Update log display with current file content
                    if (output) {
                        syncEmojiModel.logText = output;
                    }

                    // Adaptive polling interval: speed up when log grows, slow down when idle
                    var sizeNow = output.length;
                    if (sizeNow > syncEmojiModel.lastLogSize) {
                        syncEmojiModel.pollIntervalMs = 1000; // active
                    } else {
                        syncEmojiModel.pollIntervalMs = 5000; // idle
                    }
                    syncEmojiModel.lastLogSize = sizeNow;
                    syncPollTimer.interval = syncEmojiModel.pollIntervalMs;

                    // Check if we have the exit code (means script finished)
                    if (output && output.indexOf('EXIT:') !== -1) {
                        var match = output.match(/EXIT:(\\d+)/);
                        var exitCode = match ? parseInt(match[1]) : -1;

                        // Also verify SYNC_COMPLETE is present
                        var hasComplete = output.indexOf('SYNC_COMPLETE') !== -1;
                        var hasNetError = output.indexOf('SYNC_NET_ERROR') !== -1;

                        console.log('Sync finished - EXIT:' + exitCode + ', has SYNC_COMPLETE: ' + hasComplete);
                        syncEmojiModel.addLog('Sync finished - EXIT:' + exitCode + ', has SYNC_COMPLETE: ' + hasComplete);

                        syncPollTimer.stop();

                        if (exitCode === 0 && hasComplete) {
                            syncEmojiModel.onSyncComplete();
                        } else if (hasNetError) {
                            console.error('Network error during sync');
                            syncEmojiModel.onSyncNetworkError();
                        } else {
                            console.error('Sync issue - exit code: ' + exitCode + ', complete marker: ' + hasComplete);
                            syncEmojiModel.onSyncError();
                        }
                    } else {
                        // Still in progress
                        console.log('Sync in progress... (polling)');
                    }

                    disconnectSource(sourceName);
                    Qt.callLater(function() { destroy(); });
                }
            }
            `, syncEmojiButton);

            reader.connectSource(readCmd);
        }

        function onSyncComplete() {
            isSyncing = false
            statusText = i18n('Sync completed')
            syncPollTimer.stop()
            addLog('✓ Sync completed successfully')
            resetStatusTimer.restart()
        }

        function onSyncError() {
            isSyncing = false
            statusText = i18n('Sync failed')
            syncPollTimer.stop()
            addLog('✗ Sync failed or timed out')
            resetStatusTimer.restart()
        }

        function onSyncNetworkError() {
            isSyncing = false
            networkError = true
            statusText = i18n('Network error')
            syncPollTimer.stop()
            addLog('✗ Network error: Unicode site unreachable')
            resetStatusTimer.restart()
        }
    }

    // =========================================================================
    // Timers
    // =========================================================================

    // Poll timer to check sync status
    Timer {
        id: syncPollTimer
        interval: syncEmojiModel ? syncEmojiModel.pollIntervalMs : 1000
        running: false
        repeat: true
        onTriggered: syncEmojiModel.checkSyncStatus()
    }

    // Small timer to reset the button label after showing completion/error
    Timer {
        id: resetStatusTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            if (!syncEmojiModel.isSyncing) {
                syncEmojiModel.statusText = i18n('Sync emoji database from Unicode')
            }
        }
    }
}
