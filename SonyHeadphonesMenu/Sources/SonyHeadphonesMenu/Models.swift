import SwiftUI

enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

enum NcAsmMode: Int, CaseIterable, Identifiable, Sendable {
    case noiseCancelling = 0
    case ambientSound = 1
    case off = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .noiseCancelling: "NC"
        case .ambientSound: "外音取り込み"
        case .off: "OFF"
        }
    }

    var icon: String {
        switch self {
        case .noiseCancelling: "shield.checkered"
        case .ambientSound: "ear"
        case .off: "speaker.slash"
        }
    }

    var tint: Color {
        switch self {
        case .noiseCancelling: .blue
        case .ambientSound: .green
        case .off: .secondary
        }
    }
}

enum AudioCodec: Int, Sendable {
    case unsettled = 0x00
    case sbc = 0x01
    case aac = 0x02
    case ldac = 0x10
    case aptX = 0x20
    case aptXHD = 0x21
    case lc3 = 0x30
    case other = 0xFF

    var label: String {
        switch self {
        case .unsettled: "---"
        case .sbc: "SBC"
        case .aac: "AAC"
        case .ldac: "LDAC"
        case .aptX: "aptX"
        case .aptXHD: "aptX HD"
        case .lc3: "LC3"
        case .other: "Other"
        }
    }
}

/// Raw values must match `mdr::v2::t1::EqPresetId` in `ProtocolV2T1.hpp` (not sequential 0x08…).
enum EqPreset: Int, CaseIterable, Identifiable, Sendable {
    case off = 0x00
    case rock = 0x01
    case pop = 0x02
    case jazz = 0x03
    case dance = 0x04
    case edm = 0x05
    case rAndBHipHop = 0x06
    case acoustic = 0x07
    case bright = 0x10
    case excited = 0x11
    case mellow = 0x12
    case relaxed = 0x13
    case vocal = 0x14
    case treble = 0x15
    case bass = 0x16
    case speech = 0x17
    case gaming = 0x20
    case fps1 = 0x21
    case fps2 = 0x22
    case fps3 = 0x23
    case heavy = 0x30
    case clear = 0x31
    case hard = 0x32
    case soft = 0x33
    case custom = 0xA0
    case user1 = 0xA1
    case user2 = 0xA2
    case user3 = 0xA3
    case user4 = 0xA4
    case user5 = 0xA5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .off: "Off"
        case .rock: "Rock"
        case .pop: "Pop"
        case .jazz: "Jazz"
        case .dance: "Dance"
        case .edm: "EDM"
        case .rAndBHipHop: "R&B/Hip-Hop"
        case .acoustic: "Acoustic"
        case .bright: "Bright"
        case .excited: "Excited"
        case .mellow: "Mellow"
        case .relaxed: "Relaxed"
        case .vocal: "Vocal"
        case .treble: "Treble"
        case .bass: "Bass"
        case .speech: "Speech"
        case .gaming: "Gaming"
        case .fps1: "FPS 1"
        case .fps2: "FPS 2"
        case .fps3: "FPS 3"
        case .heavy: "Heavy"
        case .clear: "Clear"
        case .hard: "Hard"
        case .soft: "Soft"
        case .custom: "Custom"
        case .user1: "User Setting 1"
        case .user2: "User Setting 2"
        case .user3: "User Setting 3"
        case .user4: "User Setting 4"
        case .user5: "User Setting 5"
        }
    }

    /// Presets whose EQ steps are stored on the device; refresh with GET_PARAM after apply.
    var needsStoredEqRefresh: Bool {
        switch self {
        case .custom, .user1, .user2, .user3, .user4, .user5: true
        default: false
        }
    }

    var showsEqBandsEditor: Bool { needsStoredEqRefresh }
}

enum AudioPriority: Int, CaseIterable, Identifiable, Sendable {
    case soundQuality = 0
    case connectionStability = 1
    case lowLatency = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .soundQuality: "音質優先"
        case .connectionStability: "接続安定性"
        case .lowLatency: "低遅延 (Beta)"
        }
    }
}

struct BatteryInfo: Sendable, Equatable {
    var level: Int = 0
    var isCharging: Bool = false
}

struct DiscoveredDevice: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
}
