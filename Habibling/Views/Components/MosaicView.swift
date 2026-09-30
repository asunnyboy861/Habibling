import SwiftUI

struct MosaicView: View {
    var values: [Date: Double]
    var days: [Date]
    var accent: Color

    private let cellSize: CGFloat = 11
    private let gap: CGFloat = 2
    private let calendar = Calendar.current

    private var weeks: [[Date]] {
        stride(from: 0, to: days.count, by: 7).map { offset in
            Array(days[offset..<min(offset + 7, days.count)])
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: gap) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: gap) {
                        ForEach(week, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .fill(color(for: day))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func color(for day: Date) -> Color {
        let value = values[calendar.startOfDay(for: day)]
        guard let value else { return Color(.systemGray5).opacity(0.5) }
        if value <= 0 { return Color(.systemGray5) }
        return accent.opacity(0.25 + 0.75 * min(1, value))
    }
}
