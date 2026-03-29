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
                }
            }

            if manager.eqPreset == .custom {
                eqBandsView
            }
        }
    }

    private var eqBandsView: some View {
        let labels = ["400", "1k", "2.5k", "6.3k", "16k"]
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                eqBand(index: i, label: labels[i])
            }
        }
        .frame(height: 80)
        .padding(.vertical, 4)
        .transition(.opacity)
    }

    private func eqBand(index: Int, label: String) -> some View {
        @Bindable var m = manager
        return VStack(spacing: 4) {
            GeometryReader { geo in
                let height = geo.size.height
                let normalizedValue = (manager.eqBands[index] + 10) / 20
                let barHeight = max(6, height * normalizedValue)

                ZStack(alignment: .bottom) {
                    // Track
                    Capsule()
                        .fill(.quaternary.opacity(0.3))
                        .frame(width: 6)

                    // Active Bar
                    Capsule()
                        .fill(.tint.opacity(0.8))
                        .frame(width: 6, height: barHeight)
                        .glassEffect(in: .capsule)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle().inset(by: -10)) // Larger hit area
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            manager.recordUserActivity()
                            let y = value.location.y
                            let ratio = 1.0 - (y / height)
                            let newValue = min(10, max(-10, ratio * 20 - 10))
                            m.eqBands[index] = newValue
                        }
                )
            }

            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
