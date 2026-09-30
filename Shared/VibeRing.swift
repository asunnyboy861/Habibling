import SwiftUI

public struct VibeRing: View {
    public var progress: Double
    public var lineWidth: CGFloat = 10
    public var label: String?
    public var sublabel: String?

    public init(progress: Double, lineWidth: CGFloat = 10, label: String? = nil, sublabel: String? = nil) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.label = label
        self.sublabel = sublabel
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.accent.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: progress)
            VStack(spacing: 0) {
                if let label {
                    Text(label)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.5)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(AppTheme.pixelCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(lineWidth + 4)
        }
    }
}
