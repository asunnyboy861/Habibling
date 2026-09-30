import Combine
import SwiftUI

public struct PixelPetView: View {
    public var stage: PetStage
    public var mood: PetMood
    public var bodyColor: Color = AppTheme.accent
    public var accentColor: Color = Color(hex: PetSeason.current(from: .now).accentHex)
    public var animated: Bool = true

    @State private var frame = 0
    private let timer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    public init(stage: PetStage, mood: PetMood, bodyColor: Color = AppTheme.accent,
                accentColor: Color = Color(hex: PetSeason.current(from: .now).accentHex), animated: Bool = true) {
        self.stage = stage
        self.mood = mood
        self.bodyColor = bodyColor
        self.accentColor = accentColor
        self.animated = animated
    }

    public var body: some View {
        Canvas { context, size in
            let grid = PetSpriteGrid(stage: stage, mood: mood, frame: animated ? frame : 0)
            let cell = min(size.width, size.height) / CGFloat(PetSpriteGrid.size)
            let originX = (size.width - cell * CGFloat(PetSpriteGrid.size)) / 2
            let originY = (size.height - cell * CGFloat(PetSpriteGrid.size)) / 2
            for y in 0..<PetSpriteGrid.size {
                for x in 0..<PetSpriteGrid.size {
                    if let color = grid.color(at: x, y: y, bodyColor: bodyColor, accentColor: accentColor) {
                        let rect = CGRect(x: originX + CGFloat(x) * cell,
                                          y: originY + CGFloat(y) * cell,
                                          width: cell + 0.5,
                                          height: cell + 0.5)
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .onReceive(timer) { _ in guard animated else { return }; frame = frame == 0 ? 1 : 0 }
    }
}
