import SwiftUI

struct SecondCursorView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            CursorShape()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            CursorShape()
                .stroke(Color.blue, lineWidth: 1.5)
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .offset(x: 19, y: 22)
        }
        .frame(width: 34, height: 34)
        .opacity(model.aiCursorVisible ? 1 : 0)
        .accessibilityHidden(true)
    }
}

private struct CursorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 3, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 5))
        path.addLine(to: CGPoint(x: rect.minX + 13, y: rect.maxY - 14))
        path.addLine(to: CGPoint(x: rect.minX + 18, y: rect.maxY - 3))
        path.addLine(to: CGPoint(x: rect.minX + 24, y: rect.maxY - 6))
        path.addLine(to: CGPoint(x: rect.minX + 19, y: rect.maxY - 17))
        path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.maxY - 17))
        path.closeSubpath()
        return path
    }
}
