import SwiftUI

struct MonthCalendar: View {
    var values: [Date: Double]
    var month: Date
    var accent: Color
    var showDayNumbers = true
    var onEdit: ((Date) -> Void)?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let symbols = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthStart: Date? {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month))
    }

    private var days: [Date] {
        guard let start = monthStart,
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let blanks = calendar.component(.weekday, from: start) - 1
        let dayDates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
        return Array(repeating: Date.distantFuture, count: blanks) + dayDates
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(symbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    cell(for: day)
                }
            }
        }
    }

    private func fillColor(isPlaceholder: Bool, value: Double?) -> Color {
        if isPlaceholder { return .clear }
        if let value {
            return value <= 0 ? Color(.systemGray5) : accent.opacity(0.25 + 0.75 * min(1, value))
        }
        return Color(.systemGray6)
    }

    @ViewBuilder
    private func cell(for day: Date) -> some View {
        let isPlaceholder = day == .distantFuture
        let value = isPlaceholder ? nil : values[calendar.startOfDay(for: day)]
        let fill = fillColor(isPlaceholder: isPlaceholder, value: value)
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(fill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if showDayNumbers, !isPlaceholder {
                    let isBright = (value ?? 0) > 0.5
                    Text("\(calendar.component(.day, from: day))")
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(isBright ? Color.white : Color.secondary)
                }
            }
            .onTapGesture {
                if !isPlaceholder, onEdit != nil {
                    onEdit?(day)
                }
            }
    }
}
