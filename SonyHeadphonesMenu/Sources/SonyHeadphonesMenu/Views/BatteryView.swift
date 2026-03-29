import SwiftUI

struct BatteryView: View {
    @Environment(HeadphonesManager.self) private var manager

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                batteryCell(label: "L", info: manager.batteryLeft, icon: manager.batteryIconLeft)
                batteryCell(label: "R", info: manager.batteryRight, icon: manager.batteryIconRight)
                if manager.hasCaseBattery {
                    batteryCell(label: "Case", info: manager.batteryCase, icon: "case.fill")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func batteryCell(label: String, info: BatteryInfo, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(batteryColor(info.level))
                .symbolEffect(.pulse, isActive: info.isCharging)

            Text("\(info.level)%")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .monospacedDigit()

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassEffect(in: .rect(cornerRadius: 10))
    }

    private func batteryColor(_ level: Int) -> Color {
        switch level {
        case 51...100: .green
        case 21...50: .orange
        default: .red
        }
    }
}
