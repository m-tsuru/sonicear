import SwiftUI

struct DeviceHeaderView: View {
    @Environment(HeadphonesManager.self) private var manager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "headphones")
                .font(.system(size: 28))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(manager.modelName)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(manager.audioCodec.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassEffect(.regular.tint(.purple), in: .capsule)

                    Text("FW \(manager.firmwareVersion)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
