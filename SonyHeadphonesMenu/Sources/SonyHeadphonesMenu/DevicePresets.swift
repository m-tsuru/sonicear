import Foundation

struct DevicePresets {
    static let presetsByModel: [String: [EqPreset]] = [
        "WH-1000XM5": [
            .off, .bright, .excited, .mellow, .relaxed, .vocal,
            .treble, .bass, .speech,
            .rock, .pop, .jazz, .dance, .edm, .rAndBHipHop, .acoustic,
            .custom, .user1, .user2
        ],
        "WF-1000XM5": [
            .off, .bright, .excited, .mellow, .relaxed, .vocal,
            .treble, .bass, .speech,
            .rock, .pop, .jazz, .dance, .edm, .rAndBHipHop, .acoustic,
            .custom, .user1, .user2
        ],
        "WF-C510": [
            .off, .vocal, .treble, .bass, .speech, .rock, .pop, .jazz,
            .custom, .user1
        ],
        "LinkBuds S": [
            .off, .bright, .excited, .mellow, .relaxed, .vocal,
            .treble, .bass, .speech, .custom, .user1, .user2
        ]
    ]

    static func availablePresets(for modelName: String) -> [EqPreset] {
        // 部分一致で検索（WH-1000XM5 (Mac) のようなケースを考慮）
        for (model, presets) in presetsByModel {
            if modelName.contains(model) {
                return presets
            }
        }
        // 一致しなければ全プリセットを返す
        return EqPreset.allCases
    }
}
