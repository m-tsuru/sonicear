import SwiftUI

struct NoiseCancellingView: View {
    @Environment(HeadphonesManager.self) private var manager
    @Namespace private var ncNamespace

    private var activeMode: NcAsmMode? {
        manager.ncAsmEnabled ? manager.ncAsmMode : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("ノイズコントロール", systemImage: "waveform.path")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            modeSelector

            if manager.ncAsmEnabled && manager.ncAsmMode == .ambientSound {
                ambientControls
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var modeSelector: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(NcAsmMode.allCases) { mode in
                    modeButton(mode)
                }
            }
        }
    }

    private func modeButton(_ mode: NcAsmMode) -> some View {
        let isSelected = (mode == .off && !manager.ncAsmEnabled)
            || (manager.ncAsmEnabled && mode != .off && mode == manager.ncAsmMode)

        return Button {
            withAnimation(.smooth(duration: 0.3)) {
                manager.setNcAsmMode(mode)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.body)
                Text(mode.label)
                    .font(.caption2.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(mode.tint).interactive() : .regular.interactive(),
            in: .rect(cornerRadius: 10)
        )
        .glassEffectID(mode.id, in: ncNamespace)
    }

    private var ambientControls: some View {
        @Bindable var m = manager
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: "speaker.wave.1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $m.ambientSoundLevel, in: 1...20, step: 1)
                    .onChange(of: manager.ambientSoundLevel) {
                        manager.recordUserActivity()
                    }
                Image(systemName: "speaker.wave.3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(manager.ambientSoundLevel))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 24, alignment: .trailing)
            }

            Toggle(isOn: $m.focusOnVoice) {
                Label("ボイスフォーカス", systemImage: "person.wave.2")
                    .font(.caption)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: manager.focusOnVoice) {
                manager.recordUserActivity()
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
