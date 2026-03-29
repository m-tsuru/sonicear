import SwiftUI
import CMDRBridge

private let kServiceUUID = "956C7B26-D49A-4BA8-B03F-B17D393CB6E2"
private let kPollInterval: Duration = .milliseconds(50)

@Observable
@MainActor
final class HeadphonesManager {
    // MARK: - Connection

    var connectionState: ConnectionState = .disconnected
    var discoveredDevices: [DiscoveredDevice] = []
    private var isScanning = false

    // MARK: - Device Info

    var modelName = ""
    var firmwareVersion = ""
    var macAddress = ""
    var audioCodec: AudioCodec = .unsettled

    // MARK: - Battery

    var batteryLeft = BatteryInfo()
    var batteryRight = BatteryInfo()
    var batteryCase = BatteryInfo()
    var hasCaseBattery = false

    // MARK: - NC/ASM

    var ncAsmEnabled = true
    var ncAsmMode: NcAsmMode = .noiseCancelling
    var ambientSoundLevel: Double = 10
    var focusOnVoice = false

    // MARK: - EQ

    var eqPreset: EqPreset = .off
    var eqBands: [Double] = Array(repeating: 0, count: 5)
    var clearBass: Double = 0

    // MARK: - DSEE

    var dseeEnabled = false

    // MARK: - Playback

    var trackTitle = ""
    var trackArtist = ""
    var trackAlbum = ""
    var isPlaying = false
    var volume: Double = 15

    // MARK: - Audio Priority

    var audioPriority: AudioPriority = .soundQuality

    // MARK: - Features

    var speakToChatEnabled = false
    var autoPauseEnabled = true
    var multipointEnabled = false

    // MARK: - Activity Lock

    private var lastUserActivity = Date.distantPast
    private let kActivityLockDuration: TimeInterval = 1.5

    func recordUserActivity() {
        lastUserActivity = Date()
    }

    private var isUserInteracting: Bool {
        Date().timeIntervalSince(lastUserActivity) < kActivityLockDuration
    }

    // MARK: - Computed

    var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    var isInitialSyncing: Bool {
        phase == .waitingForConnection || phase == .waitingForInit || phase == .waitingForSync
    }

    var batteryIconLeft: String {
        batteryIcon(level: batteryLeft.level, charging: batteryLeft.isCharging)
    }

    var batteryIconRight: String {
        batteryIcon(level: batteryRight.level, charging: batteryRight.isCharging)
    }

    var menuBarBatteryText: String {
        guard isConnected else { return "" }
        let avg = (batteryLeft.level + batteryRight.level) / 2
        return "\(avg)%"
    }

    private static func decodeString(_ buf: [CChar]) -> String {
        buf.withUnsafeBufferPointer { ptr in
            guard let base = ptr.baseAddress else { return "" }
            let len = strnlen(base, ptr.count)
            return String(
                decoding: UnsafeRawBufferPointer(start: base, count: len),
                as: UTF8.self
            )
        }
    }

    // MARK: - C Library Handles

    private var platformConnection: OpaquePointer?
    private var connection: UnsafeMutablePointer<MDRConnection>?
    private var headphones: OpaquePointer?
    private var eventLoopTask: Task<Void, Never>?
    private var phase: Phase = .idle

    private enum Phase {
        case idle
        case waitingForConnection
        case waitingForInit
        case waitingForSync
        case running
    }

    // MARK: - Connection Lifecycle

    private func ensureConnection() -> UnsafeMutablePointer<MDRConnection>? {
        if let connection { return connection }
        platformConnection = mdrConnectionMacOSCreate()
        guard let pc = platformConnection else { return nil }
        connection = mdrConnectionMacOSGet(pc)
        return connection
    }

    private func teardownConnection() {
        if let hp = headphones {
            mdrHeadphonesDestroy(hp)
            headphones = nil
        }
        if let conn = connection {
            mdrConnectionDisconnect(conn)
        }
        if let pc = platformConnection {
            mdrConnectionMacOSDestroy(pc)
            platformConnection = nil
        }
        connection = nil
    }

    // MARK: - Public Actions

    func scanDevices() {
        guard !isScanning else { return }
        guard let conn = ensureConnection() else { return }
        
        isScanning = true
        var pList: UnsafeMutablePointer<MDRDeviceInfo>?
        var count: Int32 = 0
        let result = mdrConnectionGetDevicesList(conn, &pList, &count)
        
        if result == MDR_RESULT_OK {
            if count > 0, let list = pList {
                discoveredDevices = (0..<Int(count)).map { i in
                    var info = list[i]
                    let name = withUnsafeBytes(of: &info.szDeviceName) { buf in
                        Self.decodeString(Array(buf.bindMemory(to: CChar.self)))
                    }
                    let mac = withUnsafeBytes(of: &info.szDeviceMacAddress) { buf in
                        Self.decodeString(Array(buf.bindMemory(to: CChar.self)))
                    }
                    return DiscoveredDevice(id: mac, name: name)
                }
                mdrConnectionFreeDevicesList(conn, &pList)
                isScanning = false
            } else if discoveredDevices.isEmpty {
                // If we got 0 devices and we have nothing, try once more after a short delay
                // specifically for the first-run experience.
                Task {
                    try? await Task.sleep(for: .milliseconds(1500))
                    isScanning = false
                    scanDevices()
                }
            } else {
                isScanning = false
            }
        } else {
            isScanning = false
        }
    }

    func connect(to device: DiscoveredDevice) {
        guard let conn = ensureConnection() else {
            connectionState = .error("接続の作成に失敗しました")
            return
        }

        let result = mdrConnectionConnect(conn, device.id, kServiceUUID)
        if result != MDR_RESULT_OK && result != MDR_RESULT_INPROGRESS {
            let errPtr = mdrConnectionGetLastError(conn)!
            let error = String(decoding: UnsafeRawBufferPointer(start: errPtr, count: strlen(errPtr)), as: UTF8.self)
            connectionState = .error(error)
            return
        }

        connectionState = .connecting
        phase = .waitingForConnection
        startEventLoop()
    }

    func disconnect() {
        eventLoopTask?.cancel()
        eventLoopTask = nil
        teardownConnection()
        phase = .idle
        connectionState = .disconnected
        resetState()
    }

    func setNcAsmMode(_ mode: NcAsmMode) {
        recordUserActivity()
        if mode == .off {
            ncAsmEnabled = false
        } else {
            ncAsmEnabled = true
            ncAsmMode = mode
        }
    }

    func setEqPreset(_ preset: EqPreset) {
        recordUserActivity()
        eqPreset = preset
        flushPendingChangesToDevice()
    }

    /// `pushAllToDevice` と初回コミットをすぐ実行する（EQ など、ポーリング待ちだと遅れる場合用）。
    func flushPendingChangesToDevice() {
        guard let hp = headphones, phase == .running else { return }
        pushAllToDevice(hp)
        if mdrHeadphonesIsDirty(hp) == MDR_RESULT_INPROGRESS,
           mdrHeadphonesRequestIsReady(hp) == MDR_RESULT_OK {
            _ = mdrHeadphonesRequestCommitV2(hp)
        }
        // Custom / User: イヤホン側に保存されたバンドを読み直す（GET は dirty でなくても送る）
        if eqPreset.needsStoredEqRefresh {
            _ = mdrHeadphonesRequestEqParamGet(hp)
        }
    }

    /// 現在の EQ プリセット／バンドをデバイスから再取得する（メニューから同じ User を選び直したときなど）。
    func refreshEqFromDevice() {
        guard let hp = headphones, phase == .running else { return }
        _ = mdrHeadphonesRequestEqParamGet(hp)
    }

    func togglePlayPause() {
        recordUserActivity()
        guard let hp = headphones else {
            isPlaying.toggle()
            return
        }
        let control: Int32 = isPlaying ? 0x01 : 0x07
        mdrHeadphonesSetPlaybackControl(hp, control)
        isPlaying.toggle()
    }

    func nextTrack() {
        recordUserActivity()
        guard let hp = headphones else { return }
        mdrHeadphonesSetPlaybackControl(hp, 0x02)
    }

    func previousTrack() {
        recordUserActivity()
        guard let hp = headphones else { return }
        mdrHeadphonesSetPlaybackControl(hp, 0x03)
    }

    func powerOff() {
        if let hp = headphones {
            mdrHeadphonesSetShutdown(hp)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            disconnect()
        }
    }

    // MARK: - Event Loop

    private func startEventLoop() {
        eventLoopTask?.cancel()
        eventLoopTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.pollOnce()
                try? await Task.sleep(for: kPollInterval)
            }
        }
    }

    private func pollOnce() {
        guard let conn = connection else { return }

        switch phase {
        case .idle:
            return

        case .waitingForConnection:
            let result = mdrConnectionPoll(conn, 0)
            switch result {
            case MDR_RESULT_OK:
                headphones = mdrHeadphonesCreate(conn)
                guard let hp = headphones else {
                    connectionState = .error("ヘッドホンインスタンスの作成に失敗")
                    phase = .idle
                    return
                }
                if mdrHeadphonesRequestInitV2(hp) == MDR_RESULT_OK {
                    phase = .waitingForInit
                    connectionState = .connected
                } else {
                    connectionState = .error("初期化リクエストに失敗")
                    phase = .idle
                }

            case MDR_RESULT_ERROR_TIMEOUT, MDR_RESULT_INPROGRESS:
                break

            default:
                let errPtr = mdrConnectionGetLastError(conn)!
                let error = String(decoding: UnsafeRawBufferPointer(start: errPtr, count: strlen(errPtr)), as: UTF8.self)
                connectionState = .error(error)
                phase = .idle
                teardownConnection()
            }

        case .waitingForInit, .waitingForSync, .running:
            guard let hp = headphones else { return }
            pollHeadphones(hp)
        }
    }

    private func pollHeadphones(_ hp: OpaquePointer) {
        let event = mdrHeadphonesPollEvents(hp)

        switch event {
        case MDR_HEADPHONES_TASK_INIT_OK:
            // Init coroutine has already populated many properties; pull into UI before sync.
            syncAllFromDevice(hp, force: true)
            phase = .waitingForSync
            mdrHeadphonesRequestSyncV2(hp)

        case MDR_HEADPHONES_TASK_SYNC_OK:
            // Keep phase at .waitingForSync until after sync so isInitialSyncing stays true and
            // sync is not skipped when the user recently interacted (e.g. choosing a device).
            syncAllFromDevice(hp, force: true)
            phase = .running

        case MDR_HEADPHONES_TASK_COMMIT_OK:
            syncAllFromDevice(hp, force: true)

        case MDR_HEADPHONES_IDLE:
            // Do not push/commit until the first RequestSyncV2 has finished; defaults would dirty
            // the C++ layer and commit spurious state before device values are known.
            guard phase == .running else { break }
            pushAllToDevice(hp)
            if mdrHeadphonesIsDirty(hp) == MDR_RESULT_INPROGRESS,
               mdrHeadphonesRequestIsReady(hp) == MDR_RESULT_OK {
                mdrHeadphonesRequestCommitV2(hp)
            }

        case MDR_HEADPHONES_ERROR:
            let errPtr = mdrHeadphonesGetLastError(hp)!
            let error = String(decoding: UnsafeRawBufferPointer(start: errPtr, count: strlen(errPtr)), as: UTF8.self)
            connectionState = .error(error)
            disconnect()

        default:
            if event > 0 {
                handleDeviceEvent(event, hp: hp)
            }
        }
    }

    // MARK: - State Sync: Device -> Swift

    private func syncAllFromDevice(_ hp: OpaquePointer, force: Bool = false) {
        if !force && !isInitialSyncing && isUserInteracting { return }
        syncBatteryFromDevice(hp)
        syncDeviceInfoFromDevice(hp)
        syncNcAsmFromDevice(hp)
        syncEqFromDevice(hp)
        syncPlaybackFromDevice(hp)
        syncDseeFromDevice(hp)
        syncAudioPriorityFromDevice(hp)
        syncSpeakToChatFromDevice(hp)
        syncGeneralSettingsFromDevice(hp)
    }

    private func handleDeviceEvent(_ event: Int32, hp: OpaquePointer) {
        // During init/sync, always apply device events so battery/metadata arrive even if the user
        // just clicked in the UI to connect.
        if isUserInteracting && phase == .running { return }
        switch event {
        case MDR_HEADPHONES_EVT_BATTERY:
            syncBatteryFromDevice(hp)
        case MDR_HEADPHONES_EVT_NCASM_PARAM:
            syncNcAsmFromDevice(hp)
        case MDR_HEADPHONES_EVT_EQUALIZER_PARAM, MDR_HEADPHONES_EVT_EQUALIZER_AVAILABLE:
            syncEqFromDevice(hp)
        case MDR_HEADPHONES_EVT_PLAYBACK_VOLUME, MDR_HEADPHONES_EVT_PLAYBACK_PLAY_PAUSE,
             MDR_HEADPHONES_EVT_PLAYBACK_METADATA:
            syncPlaybackFromDevice(hp)
        case MDR_HEADPHONES_EVT_UPSCALING_MODE:
            syncDseeFromDevice(hp)
        case MDR_HEADPHONES_EVT_CONNECTION_MODE:
            syncAudioPriorityFromDevice(hp)
        case MDR_HEADPHONES_EVT_SPEAK_TO_CHAT_ENABLED, MDR_HEADPHONES_EVT_SPEAK_TO_CHAT_PARAM:
            syncSpeakToChatFromDevice(hp)
        case MDR_HEADPHONES_EVT_CODEC:
            syncDeviceInfoFromDevice(hp)
        case MDR_HEADPHONES_EVT_GENERAL_SETTING_1, MDR_HEADPHONES_EVT_GENERAL_SETTING_2:
            syncGeneralSettingsFromDevice(hp)
        default:
            break
        }
    }

    private func syncBatteryFromDevice(_ hp: OpaquePointer) {
        var level: UInt8 = 0, charging: UInt8 = 0

        mdrHeadphonesGetBatteryLeft(hp, &level, &charging)
        batteryLeft = BatteryInfo(level: Int(level), isCharging: charging == 1)

        mdrHeadphonesGetBatteryRight(hp, &level, &charging)
        batteryRight = BatteryInfo(level: Int(level), isCharging: charging == 1)

        mdrHeadphonesGetBatteryCase(hp, &level, &charging)
        batteryCase = BatteryInfo(level: Int(level), isCharging: charging == 1)
        hasCaseBattery = batteryCase.level > 0
    }

    private func syncDeviceInfoFromDevice(_ hp: OpaquePointer) {
        var buf = [CChar](repeating: 0, count: 256)

        mdrHeadphonesGetModelName(hp, &buf, Int32(buf.count))
        modelName = Self.decodeString(buf)

        mdrHeadphonesGetFWVersion(hp, &buf, Int32(buf.count))
        firmwareVersion = Self.decodeString(buf)

        mdrHeadphonesGetUniqueId(hp, &buf, Int32(buf.count))
        macAddress = Self.decodeString(buf)

        var codec: Int32 = 0
        mdrHeadphonesGetAudioCodec(hp, &codec)
        audioCodec = AudioCodec(rawValue: Int(codec)) ?? .other
    }

    private func syncNcAsmFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0

        mdrHeadphonesGetNcAsmEnabled(hp, &value)
        ncAsmEnabled = value != 0

        mdrHeadphonesGetNcAsmMode(hp, &value)
        if let mode = NcAsmMode(rawValue: Int(value)) {
            ncAsmMode = mode
        }

        mdrHeadphonesGetAmbientLevel(hp, &value)
        ambientSoundLevel = Double(value)

        mdrHeadphonesGetFocusOnVoice(hp, &value)
        focusOnVoice = value != 0
    }

    private func syncEqFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0

        mdrHeadphonesGetEqPreset(hp, &value)
        let raw = Int(value)
        if let preset = EqPreset(rawValue: raw) {
            eqPreset = preset
        } else if (0xB0 ... 0xBF).contains(raw) {
            // ARTIST_COLLAB* — バンド編集は Custom 相当として扱う
            eqPreset = .custom
        }

        mdrHeadphonesGetClearBass(hp, &value)
        clearBass = Double(value)

        var count: Int32 = 0
        mdrHeadphonesGetEqBands(hp, nil, &count)
        if count > 0 {
            var bands = [Int32](repeating: 0, count: Int(count))
            mdrHeadphonesGetEqBands(hp, &bands, &count)
            eqBands = bands.map { Double($0) }
        }
    }

    private func syncPlaybackFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0
        var buf = [CChar](repeating: 0, count: 256)

        mdrHeadphonesGetVolume(hp, &value)
        volume = Double(value)

        mdrHeadphonesGetPlaybackStatus(hp, &value)
        isPlaying = value == 0x01

        mdrHeadphonesGetTrackTitle(hp, &buf, Int32(buf.count))
        trackTitle = Self.decodeString(buf)

        mdrHeadphonesGetTrackArtist(hp, &buf, Int32(buf.count))
        trackArtist = Self.decodeString(buf)

        mdrHeadphonesGetTrackAlbum(hp, &buf, Int32(buf.count))
        trackAlbum = Self.decodeString(buf)
    }

    private func syncDseeFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0
        mdrHeadphonesGetUpscalingEnabled(hp, &value)
        dseeEnabled = value != 0
    }

    private func syncAudioPriorityFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0
        mdrHeadphonesGetAudioPriority(hp, &value)
        if let priority = AudioPriority(rawValue: Int(value)) {
            audioPriority = priority
        }
    }

    private func syncSpeakToChatFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0
        mdrHeadphonesGetSpeakToChatEnabled(hp, &value)
        speakToChatEnabled = value != 0
    }

    private func syncGeneralSettingsFromDevice(_ hp: OpaquePointer) {
        var value: Int32 = 0

        mdrHeadphonesGetMultipointEnabled(hp, &value)
        multipointEnabled = value != 0

        mdrHeadphonesGetAutoPauseEnabled(hp, &value)
        autoPauseEnabled = value != 0
    }

    // MARK: - State Sync: Swift -> Device

    private func pushAllToDevice(_ hp: OpaquePointer) {
        var val: Int32 = 0

        // NC/ASM
        mdrHeadphonesGetNcAsmEnabled(hp, &val)
        if (ncAsmEnabled ? 1 : 0) != val {
            mdrHeadphonesSetNcAsmEnabled(hp, ncAsmEnabled ? 1 : 0)
        }
        
        mdrHeadphonesGetNcAsmMode(hp, &val)
        if Int32(ncAsmMode.rawValue) != val {
            mdrHeadphonesSetNcAsmMode(hp, Int32(ncAsmMode.rawValue))
        }

        if ncAsmEnabled && ncAsmMode == .ambientSound {
            mdrHeadphonesGetAmbientLevel(hp, &val)
            if Int32(ambientSoundLevel) != val {
                mdrHeadphonesSetAmbientLevel(hp, Int32(ambientSoundLevel))
            }
            
            mdrHeadphonesGetFocusOnVoice(hp, &val)
            if (focusOnVoice ? 1 : 0) != val {
                mdrHeadphonesSetFocusOnVoice(hp, focusOnVoice ? 1 : 0)
            }
        }

        // EQ
        mdrHeadphonesGetEqPreset(hp, &val)
        let swiftPreset = Int32(eqPreset.rawValue)
        if swiftPreset != val {
            mdrHeadphonesSetEqPreset(hp, swiftPreset)
            // プリセット変更時、非カスタムなら一度だけ空バンドを送ってデバイス側のプリセット値を使わせる
            if swiftPreset < 0xA0 {
                mdrHeadphonesSetEqBands(hp, [], 0)
            }
        }
        
        if eqPreset == .custom || eqPreset.rawValue >= 0xA1 {
            mdrHeadphonesGetClearBass(hp, &val)
            if Int32(clearBass) != val {
                mdrHeadphonesSetClearBass(hp, Int32(clearBass))
            }

            var count: Int32 = 0
            mdrHeadphonesGetEqBands(hp, nil, &count)
            if count > 0 {
                var currentBands = [Int32](repeating: 0, count: Int(count))
                mdrHeadphonesGetEqBands(hp, &currentBands, &count)
                let swiftBands = eqBands.map { Int32($0) }
                if currentBands != swiftBands {
                    mdrHeadphonesSetEqBands(hp, swiftBands, Int32(swiftBands.count))
                }
            }
        }

        // DSEE / Volume / Priority
        mdrHeadphonesGetUpscalingEnabled(hp, &val)
        if (dseeEnabled ? 1 : 0) != val {
            mdrHeadphonesSetUpscalingEnabled(hp, dseeEnabled ? 1 : 0)
        }

        mdrHeadphonesGetVolume(hp, &val)
        if Int32(volume) != val {
            mdrHeadphonesSetVolume(hp, Int32(volume))
        }

        mdrHeadphonesGetAudioPriority(hp, &val)
        if Int32(audioPriority.rawValue) != val {
            mdrHeadphonesSetAudioPriority(hp, Int32(audioPriority.rawValue))
        }

        mdrHeadphonesGetSpeakToChatEnabled(hp, &val)
        if (speakToChatEnabled ? 1 : 0) != val {
            mdrHeadphonesSetSpeakToChatEnabled(hp, speakToChatEnabled ? 1 : 0)
        }

        // General
        mdrHeadphonesGetMultipointEnabled(hp, &val)
        if (multipointEnabled ? 1 : 0) != val {
            mdrHeadphonesSetMultipointEnabled(hp, multipointEnabled ? 1 : 0)
        }

        mdrHeadphonesGetAutoPauseEnabled(hp, &val)
        if (autoPauseEnabled ? 1 : 0) != val {
            mdrHeadphonesSetAutoPauseEnabled(hp, autoPauseEnabled ? 1 : 0)
        }
    }

    // MARK: - Helpers

    private func batteryIcon(level: Int, charging: Bool) -> String {
        if charging { return "battery.100percent.bolt" }
        return switch level {
        case 76...100: "battery.100percent"
        case 51...75: "battery.75percent"
        case 26...50: "battery.50percent"
        case 1...25: "battery.25percent"
        default: "battery.0percent"
        }
    }

    private func resetState() {
        modelName = ""
        firmwareVersion = ""
        macAddress = ""
        audioCodec = .unsettled
        batteryLeft = BatteryInfo()
        batteryRight = BatteryInfo()
        batteryCase = BatteryInfo()
        hasCaseBattery = false
        trackTitle = ""
        trackArtist = ""
        trackAlbum = ""
        isPlaying = false
    }
}
