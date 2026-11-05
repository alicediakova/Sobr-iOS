import SwiftUI

struct DrinkStepper: View {
    @Binding var count: Int
    var range: ClosedRange<Int>
    var caption: String
    var numberSize: CGFloat = 84

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 28) {
                stepButton(systemName: "minus", label: "Fewer drinks", enabled: count > range.lowerBound) {
                    count = max(range.lowerBound, count - 1)
                }
                Text("\(count)")
                    .font(.system(size: numberSize, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.sobrLabel)
                    .frame(minWidth: numberSize * 0.9)
                    .accessibilityLabel("\(count) drinks")
                stepButton(systemName: "plus", label: "More drinks", enabled: count < range.upperBound) {
                    count = min(range.upperBound, count + 1)
                }
            }
            .sensoryFeedback(.selection, trigger: count)

            Text(caption)
                .font(.subheadline)
                .foregroundStyle(Color.sobrSecondary)
        }
    }

    private func stepButton(systemName: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.sobrAccent)
                .frame(width: 52, height: 52)
                .background(Color.sobrAccentSoft, in: Circle())
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
        .frame(minWidth: 44, minHeight: 44)
    }
}

struct GoalProgressBar: View {
    let title: String
    let total: Int
    var maximum: Int?

    private var fraction: Double {
        CalendarMath.progressFraction(total: total, max: maximum)
    }

    private var isWarning: Bool {
        CalendarMath.isWarning(total: total, max: maximum)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.sobrSecondary)
                Spacer(minLength: 8)
                Text(valueText)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isWarning ? Color.sobrWarning : Color.sobrLabel)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.sobrTrack)
                    Capsule()
                        .fill(isWarning ? Color.sobrWarning : Color.sobrAccent)
                        .frame(width: max(0, geometry.size.width * fraction))
                }
            }
            .frame(height: 8)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(valueText)
    }

    private var valueText: String {
        if let maximum {
            return "\(total) / \(maximum)"
        }
        return "\(total)"
    }
}

struct GlanceStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Color.sobrLabel)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.sobrSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
