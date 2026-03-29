import SwiftUI

struct MenuBarContentView: View {
    @Environment(HeadphonesManager.self) private var manager

    var body: some View {
        Group {
            switch manager.connectionState {
            case .disconnected:
                ConnectionView()
            case .connecting:
                connectingView
            case .connected:
                connectedView
            case .error(let message):
                errorView(message)
            }
        }
        .frame(width: 340)
        .environment(manager)
    }

    private var connectingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("接続中...")
                .font(.headline)
            Button("キャンセル") {
                manager.disconnect()
            }
            .buttonStyle(.glass)
        }
        .padding(24)
    }

    private var connectedView: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    DeviceHeaderView()
                    Divider().padding(.horizontal)
                    BatteryView()
                    Divider().padding(.horizontal)
                    NoiseCancellingView()
                    Divider().padding(.horizontal)
                    SoundSettingsView()
                    Divider().padding(.horizontal)
                    PlaybackView()
                    Divider().padding(.horizontal)
                    footerSection
                }
                .padding(.vertical, 8)
            }
            .disabled(manager.isInitialSyncing)
            .blur(radius: manager.isInitialSyncing ? 2 : 0)

            if manager.isInitialSyncing {
                ZStack {
                    Color.black.opacity(0.1)
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("情報を同期中...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .glassEffect(in: .rect(cornerRadius: 16))
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: manager.isInitialSyncing)
    }

    private var footerSection: some View {
        HStack(spacing: 12) {
            Button {
                manager.powerOff()
            } label: {
                Label("電源OFF", systemImage: "power")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)

            Button {
                manager.disconnect()
            } label: {
                Label("切断", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("接続エラー")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("再接続") {
                manager.connectionState = .disconnected
            }
            .buttonStyle(.glass)
        }
        .padding(24)
    }
}
