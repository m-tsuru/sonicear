import SwiftUI

struct ConnectionView: View {
    @Environment(HeadphonesManager.self) private var manager

    var body: some View {
        VStack(spacing: 16) {
            header
            deviceList
            scanButton
        }
        .padding(16)
        .onAppear {
            manager.scanDevices()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "headphones.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Sony Headphones")
                .font(.headline)
            Text("接続するデバイスを選択")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var deviceList: some View {
        VStack(spacing: 8) {
            ForEach(manager.discoveredDevices) { device in
                Button {
                    manager.connect(to: device)
                } label: {
                    HStack {
                        Image(systemName: "headphones")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.body.weight(.medium))
                            Text(device.id)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .glassEffect(in: .rect(cornerRadius: 10))
            }
        }
    }

    private var scanButton: some View {
        Button {
            manager.scanDevices()
        } label: {
            Label("再スキャン", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.glass)
    }
}
