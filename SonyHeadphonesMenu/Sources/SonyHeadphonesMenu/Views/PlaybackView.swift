import SwiftUI

struct PlaybackView: View {
    @Environment(HeadphonesManager.self) private var manager

    private var hasTrackInfo: Bool {
        !manager.trackTitle.isEmpty
    }

    var body: some View {
        @Bindable var m = manager
        VStack(alignment: .leading, spacing: 10) {
            Label("再生", systemImage: "music.note")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if hasTrackInfo {
                trackInfo
            }

            playbackControls

            HStack(spacing: 8) {
                Image(systemName: volumeIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Slider(value: $m.volume, in: 0...30, step: 1)
                    .onChange(of: manager.volume) {
                        manager.recordUserActivity()
                    }

                Text("\(Int(manager.volume))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 20, alignment: .trailing)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(manager.trackTitle)
                .font(.callout.weight(.medium))
                .lineLimit(1)

            Text("\(manager.trackArtist) — \(manager.trackAlbum)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var playbackControls: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    manager.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.body)
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)

                Button {
                    manager.togglePlayPause()
                } label: {
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)

                Button {
                    manager.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.body)
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var volumeIcon: String {
        switch Int(manager.volume) {
        case 0: "speaker.slash"
        case 1...10: "speaker.wave.1"
        case 11...20: "speaker.wave.2"
        default: "speaker.wave.3"
        }
    }
}
