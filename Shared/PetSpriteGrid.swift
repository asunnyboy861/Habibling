import SwiftUI

public extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

public struct PetSpriteGrid: Equatable, Sendable {
    public static let size = 16
    public private(set) var cells: [[Character]] = []

    public init(stage: PetStage, mood: PetMood, frame: Int) {
        cells = Self.body(for: stage, frame: frame)
        Self.overlayFace(&cells, mood: mood, stage: stage)
        if stage == .egg { Self.overlayCracks(&cells, mood: mood) }
    }

    public func color(at x: Int, y: Int, bodyColor: Color, accentColor: Color) -> Color? {
        guard y < cells.count, x < cells[y].count else { return nil }
        switch cells[y][x] {
        case "#": return bodyColor
        case "+": return bodyColor.opacity(0.55)
        case "e": return Color(white: 0.12)
        case "w": return Color.white
        case "m": return Color(white: 0.25)
        case "b": return accentColor
        default: return nil
        }
    }

    private static func blank() -> [[Character]] {
        Array(repeating: Array(repeating: ".", count: size), count: size)
    }

    private static func stamp(_ grid: inout [[Character]], _ rows: [String], atX x0: Int, atY y0: Int) {
        for (dy, row) in rows.enumerated() {
            let y = y0 + dy
            guard y >= 0, y < size else { continue }
            for (dx, ch) in row.enumerated() {
                let x = x0 + dx
                guard x >= 0, x < size, ch != "." else { continue }
                grid[y][x] = ch
            }
        }
    }

    private static func body(for stage: PetStage, frame: Int) -> [[Character]] {
        var grid = blank()
        let lift = (frame == 1 && stage != .egg) ? 1 : 0
        switch stage {
        case .egg:
            stamp(&grid, [
                "....######......",
                "...########.....",
                "..##########....",
                "..##########....",
                ".############...",
                ".############...",
                ".######bb#####..",
                ".############...",
                ".############...",
                "..##########....",
                "...########.....",
                "....######......"
            ], atX: 1, atY: 2)
        case .hatchling:
            stamp(&grid, [
                ".....#####......",
                "....#######.....",
                "...##e###e##....",
                "..############..",
                "..############..",
                "..####bb#####...",
                "..############..",
                "...##########...",
                "....##....##....",
                "....##....##...."
            ], atX: 2, atY: 3 - lift)
        case .juvenile:
            stamp(&grid, [
                "......####......",
                ".....######.....",
                "....##e##e##....",
                "...##########...",
                "...##########...",
                "...####bb####...",
                "..###########...",
                "..###########...",
                "...##########...",
                "...##......##...",
                "...##......##...",
                "...###....###..."
            ], atX: 2, atY: 2 - lift)
        case .adult:
            stamp(&grid, [
                "......####...+..",
                ".....######.++..",
                "....##e##e##+...",
                "...##########...",
                "...##########...",
                "..#####bb#####..",
                "..###########...",
                "..###########...",
                "..###########...",
                "...##########...",
                "...##......##...",
                "...##......##...",
                "...###....###..."
            ], atX: 2, atY: 1 - lift)
        }
        return grid
    }

    private static func overlayFace(_ grid: inout [[Character]], mood: PetMood, stage: PetStage) {
        guard stage != .egg else { return }
        let eyeY: Int
        let mouthY: Int
        switch stage {
        case .hatchling: eyeY = 5; mouthY = 7
        case .juvenile: eyeY = 4; mouthY = 6
        default: eyeY = 3; mouthY = 5
        }
        let leftEyeX = 6
        let rightEyeX = 9
        for (y, row) in grid.enumerated() {
            for x in 0..<row.count {
                if y == eyeY && (x == leftEyeX || x == rightEyeX) && grid[y][x] == "e" {
                    grid[y][x] = mood == .sleepy ? "m" : "e"
                }
                if y == eyeY - 1 && ((x == leftEyeX && mood == .joyful) || (x == rightEyeX && mood == .joyful)) && grid[y][x] == "#" {
                    grid[y][x] = "w"
                }
            }
        }
        if mouthY < grid.count && grid[mouthY][7] == "#" {
            grid[mouthY][7] = mood == .joyful ? "m" : (mood == .sleepy ? "#" : "m")
        }
    }

    private static func overlayCracks(_ grid: inout [[Character]], mood: PetMood) {
        let crack = mood == .joyful ? 5 : 2
        for i in 0..<crack {
            let y = 4 + i
            let x = 5 + (i % 3)
            if y < grid.count && grid[y][x] == "#" { grid[y][x] = "+" }
        }
    }
}
