import SwiftUI

struct EarthIconView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                aura(time: time)
                globe(time: time)
                statusRing(time: time)
            }
            .frame(width: 72, height: 72)
            .contentShape(Circle())
            .accessibilityLabel("Earth Agent. Single click opens chat bar. Double click starts listening.")
        }
    }

    private func aura(time: TimeInterval) -> some View {
        let pulse = 0.55 + 0.20 * sin(time * 2.2)
        return ZStack {
            Circle()
                .fill(statusColor.opacity(0.18 + pulse * 0.12))
                .frame(width: 70, height: 70)
                .blur(radius: 9)
            Circle()
                .stroke(statusColor.opacity(0.28), lineWidth: 1.2)
                .frame(width: 66 + pulse * 4, height: 66 + pulse * 4)
        }
    }

    private func globe(time: TimeInterval) -> some View {
        let rotation = (time.truncatingRemainder(dividingBy: 12) / 12) * 44
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.70, green: 0.95, blue: 1.0),
                            Color(red: 0.03, green: 0.48, blue: 0.92),
                            Color(red: 0.01, green: 0.10, blue: 0.34),
                            Color(red: 0.0, green: 0.03, blue: 0.13)
                        ],
                        center: UnitPoint(x: 0.30, y: 0.22),
                        startRadius: 2,
                        endRadius: 36
                    )
                )
                .overlay(oceanTexture)
                .overlay(landLayer(rotation: rotation))
                .overlay(nightShade)
                .overlay(specularHighlight)
                .overlay(atmosphere)
                .shadow(color: .cyan.opacity(0.35), radius: 10, y: 0)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 7)
        }
        .frame(width: 58, height: 58)
        .clipShape(Circle())
    }

    private var oceanTexture: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Ellipse()
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.8)
                    .frame(width: 52, height: CGFloat(10 + index * 7))
                    .offset(y: CGFloat(index - 2) * 5)
            }
        }
    }

    private func landLayer(rotation: CGFloat) -> some View {
        ZStack {
            LandBlob(points: [
                CGPoint(x: 0.12, y: 0.38),
                CGPoint(x: 0.25, y: 0.20),
                CGPoint(x: 0.43, y: 0.24),
                CGPoint(x: 0.49, y: 0.44),
                CGPoint(x: 0.31, y: 0.52),
                CGPoint(x: 0.17, y: 0.48)
            ])
            .fill(landGradient)
            .offset(x: -18 + rotation)

            LandBlob(points: [
                CGPoint(x: 0.57, y: 0.50),
                CGPoint(x: 0.82, y: 0.38),
                CGPoint(x: 0.92, y: 0.56),
                CGPoint(x: 0.80, y: 0.82),
                CGPoint(x: 0.61, y: 0.72)
            ])
            .fill(landGradient)
            .offset(x: -18 + rotation)

            LandBlob(points: [
                CGPoint(x: 0.08, y: 0.62),
                CGPoint(x: 0.25, y: 0.56),
                CGPoint(x: 0.38, y: 0.74),
                CGPoint(x: 0.23, y: 0.91),
                CGPoint(x: 0.09, y: 0.82)
            ])
            .fill(landGradient.opacity(0.90))
            .offset(x: 28 - rotation)

            LandBlob(points: [
                CGPoint(x: 0.72, y: 0.18),
                CGPoint(x: 0.91, y: 0.25),
                CGPoint(x: 0.84, y: 0.39),
                CGPoint(x: 0.67, y: 0.35)
            ])
            .fill(landGradient.opacity(0.85))
            .offset(x: 28 - rotation)
        }
        .padding(7)
        .clipShape(Circle())
    }

    private var landGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.74, green: 0.96, blue: 0.50),
                Color(red: 0.14, green: 0.72, blue: 0.42),
                Color(red: 0.06, green: 0.42, blue: 0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var nightShade: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var specularHighlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.55), .white.opacity(0.12), .clear],
                    center: UnitPoint(x: 0.27, y: 0.20),
                    startRadius: 1,
                    endRadius: 22
                )
            )
            .blendMode(.screen)
    }

    private var atmosphere: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.88), .cyan.opacity(0.45), .blue.opacity(0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }

    private func statusRing(time: TimeInterval) -> some View {
        let active = model.status == .listening || model.status == .thinking || model.status == .working || model.isConversationMode
        let trimEnd = active ? 0.72 + 0.18 * sin(time * 2.8) : 1.0
        return Circle()
            .trim(from: active ? 0.06 : 0.0, to: trimEnd)
            .stroke(statusColor, style: StrokeStyle(lineWidth: 3.0, lineCap: .round))
            .frame(width: 64, height: 64)
            .rotationEffect(.degrees(time * 36))
            .shadow(color: statusColor.opacity(0.50), radius: 6)
    }

    private var statusColor: Color {
        if model.isConversationMode || model.status == .listening {
            return .green
        }
        switch model.status {
        case .thinking, .working:
            return .yellow
        case .waitingForConfirmation:
            return .orange
        case .failed, .stopped:
            return .red
        default:
            return .white
        }
    }
}

private struct LandBlob: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: point(first, in: rect))
        for index in points.indices.dropFirst() {
            let current = point(points[index], in: rect)
            let previous = point(points[index - 1], in: rect)
            let control = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: current, control: control)
        }
        path.closeSubpath()
        return path
    }

    private func point(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height)
    }
}
