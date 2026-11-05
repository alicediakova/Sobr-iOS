import Charts
import SwiftUI

struct WeekChartView: View {
    let weeks: [WeekBucket]
    var goal: Int?
    @Binding var selectedKey: String?

    private var yMax: Int {
        max(weeks.map(\.total).max() ?? 0, goal ?? 0, 1)
    }

    private var selected: WeekBucket? {
        weeks.first { $0.startKey == selectedKey }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(weeks) { week in
                    BarMark(
                        x: .value("Week", week.label),
                        y: .value("Drinks", week.total)
                    )
                    .foregroundStyle(barColor(for: week))
                    .cornerRadius(4)
                }
                if let goal {
                    RuleMark(y: .value("Goal", goal))
                        .foregroundStyle(Color.sobrSecondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .chartYScale(domain: 0...yMax)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(Color.sobrSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let frame = geometry[proxy.plotAreaFrame]
                            let x = location.x - frame.origin.x
                            if let label: String = proxy.value(atX: x, as: String.self),
                               let week = weeks.first(where: { $0.label == label }) {
                                selectedKey = week.startKey
                            }
                        }
                }
            }

            if let selected {
                Text(caption(for: selected))
                    .font(.footnote)
                    .foregroundStyle(Color.sobrSecondary)
            } else if goal != nil {
                Text("Dashed line is your weekly goal.")
                    .font(.footnote)
                    .foregroundStyle(Color.sobrSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last 8 weeks")
        .accessibilityValue(selected.map(caption) ?? "Tap a bar to hear that week's total")
    }

    private func barColor(for week: WeekBucket) -> Color {
        if let goal, week.total > goal {
            return Color.sobrWarning
        }
        return Color.sobrAccent
    }

    private func caption(for week: WeekBucket) -> String {
        let day = week.start.formatted(.dateTime.month(.abbreviated).day())
        let drinks = week.total == 1 ? "1 drink" : "\(week.total) drinks"
        return "Week of \(day) · \(drinks)"
    }
}
