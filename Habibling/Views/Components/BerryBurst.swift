import SwiftUI

struct BerryBurst: View {
    var trigger: Int

    struct Particle: Identifiable {
        let id: Int
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let color: Color
    }

    @State private var particles: [Particle] = []
    @State private var expanded = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: particle.size * 0.3)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(expanded ? 0.1 : 1)
                    .offset(x: expanded ? cos(particle.angle) * particle.distance : 0,
                            y: expanded ? sin(particle.angle) * particle.distance : 0)
                    .opacity(expanded ? 0 : 1)
                    .animation(.easeOut(duration: 0.65), value: expanded)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _ in fire() }
    }

    private func fire() {
        let colors = [AppTheme.accent, Color(hex: "#E8C547"), Color(hex: "#57C79A"), Color(hex: "#4FB8D9")]
        particles = (0..<16).map { index in
            Particle(id: index,
                     angle: Double(index) / 16 * 2 * .pi,
                     distance: 90 + CGFloat.random(in: -20...45),
                     size: CGFloat.random(in: 6...12),
                     color: colors.randomElement() ?? AppTheme.accent)
        }
        expanded = false
        withAnimation(.easeOut(duration: 0.65)) { expanded = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles = []
            expanded = false
        }
    }
}
