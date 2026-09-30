import Foundation
import SwiftUI
import UIKit

enum ShareRenderer {
    static func renderMosaic(values: [Date: Double], days: [Date], title: String, subtitle: String, accentHex: String) -> UIImage {
        let columns = 7
        let rows = Int(ceil(Double(days.count) / Double(columns)))
        let margin: CGFloat = 40
        let headerHeight: CGFloat = 150
        let watermarkHeight: CGFloat = 60
        let cellGap: CGFloat = 8
        let width: CGFloat = 900
        let cellSize = (width - margin * 2 - cellGap * CGFloat(columns - 1)) / CGFloat(columns)
        let height = headerHeight + CGFloat(rows) * (cellSize + cellGap) - cellGap + watermarkHeight + margin

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            let background = UIColor.white
            background.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 44, weight: .bold),
                .foregroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .medium),
                .foregroundColor: UIColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1)
            ]
            (title as NSString).draw(at: CGPoint(x: margin, y: 46), withAttributes: titleAttributes)
            (subtitle as NSString).draw(at: CGPoint(x: margin, y: 102), withAttributes: subtitleAttributes)

            let accent = UIColor(Color(hex: accentHex))
            let empty = UIColor.systemGray5
            let calendar = Calendar.current
            for (index, day) in days.enumerated() {
                let column = index % columns
                let row = index / columns
                let x = margin + CGFloat(column) * (cellSize + cellGap)
                let y = headerHeight + CGFloat(row) * (cellSize + cellGap)
                let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cellSize * 0.22)
                let score = values[calendar.startOfDay(for: day)] ?? -1
                if score < 0 {
                    empty.setFill()
                } else if score <= 0 {
                    empty.withAlphaComponent(0.7).setFill()
                } else {
                    accent.withAlphaComponent(CGColorAlpha(max(0.25, score))).setFill()
                }
                path.fill()
            }

            let watermarkAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor(red: 0.65, green: 0.65, blue: 0.7, alpha: 1)
            ]
            let watermark = "One pixel a day.  habibling.app"
            let size = (watermark as NSString).size(withAttributes: watermarkAttributes)
            (watermark as NSString).draw(at: CGPoint(x: width - margin - size.width, y: height - watermarkHeight),
                                         withAttributes: watermarkAttributes)
        }
    }

    static func monthDays(month: Date, calendar: Calendar = .current) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    static func yearDays(end: Date, calendar: Calendar = .current) -> [Date] {
        (0..<364).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: end)) }
    }
}

private func CGColorAlpha(_ value: Double) -> CGFloat {
    CGFloat(min(1, max(0, value)))
}
