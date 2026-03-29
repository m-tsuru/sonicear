import SwiftUI

struct SoundSettingsView: View {
    @Environment(HeadphonesManager.self) private var manager

    var body: some View {
        @Bindable var m = manager
        VStack(alignment: .leading, spacing: 10) {
            Label("サウンド", systemImage: "slider.horizontal.3")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            eqSection

            if manager.eqBands.count == 5 {
                HStack {
                    Text("Clear Bass")
                        .font(.caption)
                    Spacer()
                    Slider(value: $m.clearBass, in: -10...10, step: 1)
                        .frame(width: 140)
                        .onChange(of: manager.clearBass) {
                            manager.recordUserActivity()
                        }
                    Text(String(format: "%+.0f", manager.clearBass))
                        .font(.caption.monospacedDigit())
                        .frame(width: 28, alignment: .trailing)
                }
            }

            Divider()

            Toggle(isOn: $m.dseeEnabled) {
                HStack {
                    Text("DSEE")
                        .font(.caption)
                    Spacer()
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: manager.dseeEnabled) {
                manager.recordUserActivity()
            }

            HStack {
                Text("接続品質")
                    .font(.caption)
                Spacer()
                Picker("", selection: $m.audioPriority) {
                    ForEach(AudioPriority.allCases) { priority in
                        Text(priority.label).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: manager.audioPriority) {
                    manager.recordUserActivity()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var eqSection: some View {
        @Bindable var m = manager
        return VStack(spacing: 8) {
            HStack {
                Text("イコライザー")
                    .font(.caption)
                Spacer()
                Picker("", selection: $m.eqPreset) {
                    ForEach(EqPreset.allCases) { preset in
                        Text(preset.label).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                .onChange(of: manager.eqPreset) {
                    manager.recordUserActivity()
                    manager.flushPendingChangesToDevice()
                }
            }

            if manager.eqPreset.showsEqBandsEditor {
                eqBandsView
            }
        }
    }

    private var eqBandsView: some View {
        let kBand5 = ["400", "1k", "2.5k", "6.3k", "16k"]
        let kBand10 = ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
        let count = manager.eqBands.count
        let labels = count == 10 ? kBand10 : kBand5
        
        return HStack(alignment: .bottom, spacing: count == 10 ? 2 : 4) {
            ForEach(0..<count, id: \.self) { i in
                eqBand(index: i, label: labels[i])
            }
        }
        .frame(height: 80)
        .padding(.vertical, 4)
        .transition(.opacity)
    }

    private func eqBand(index: Int, label: String) -> some View {
        @Bindable var m = manager
        let isEditable = manager.eqPreset == .custom || manager.eqPreset.rawValue >= 0xA1
        let range: Double = manager.eqBands.count == 10 ? 6 : 10
        let count = manager.eqBands.count

        return VStack(spacing: 4) {
            GeometryReader { geo in
                let height = geo.size.height
                let normalizedValue = (manager.eqBands[index] + range) / (range * 2)
                let barHeight = max(6, height * normalizedValue)

                ZStack(alignment: .bottom) {
                    // Track
                    Capsule()
                        .fill(.quaternary.opacity(0.3))
                        .frame(width: 6)

                    // Active Bar
                    Capsule()
                        .fill((isEditable ? Color.accentColor : Color.secondary).opacity(0.8))
                        .frame(width: 6, height: barHeight)
                        .glassEffect(in: .capsule)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle().inset(by: -10)) // Larger hit area
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isEditable else { return }
                            manager.recordUserActivity()
                            let y = value.location.y
                            let ratio = 1.0 - (y / height)
                            let newValue = min(range, max(-range, ratio * (range * 2) - range))
                            m.eqBands[index] = newValue
                        }
                )
            }

            Text(label)
                .font(.system(size: count == 10 ? 7 : 8, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
