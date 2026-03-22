import SwiftUI

// MARK: - Colors
extension Color {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let paperDark = Color(red: 0.93, green: 0.90, blue: 0.85)
    static let inkBrown = Color(red: 0.35, green: 0.25, blue: 0.15)
    static let inkGray = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let doodleBlue = Color(red: 0.2, green: 0.4, blue: 0.6)
    static let doodleOrange = Color(red: 0.9, green: 0.5, blue: 0.2)
    static let doodleGreen = Color(red: 0.2, green: 0.6, blue: 0.3)
    static let doodleRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let highlightYellow = Color(red: 1.0, green: 0.95, blue: 0.6)
}

// MARK: - Paper Texture View
struct PaperTexture: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base paper color
                Color.paper

                // Subtle noise texture using gradient pattern
                Canvas { context, size in
                    // Draw subtle paper fibers
                    for _ in 0..<200 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let length = CGFloat.random(in: 5...20)
                        let angle = Angle.degrees(Double.random(in: 0...360))

                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(
                            to: CGPoint(
                                x: x + length * cos(angle.radians),
                                y: y + length * sin(angle.radians)
                            )
                        )

                        context.stroke(
                            path,
                            with: .color(Color.inkGray.opacity(0.05)),
                            lineWidth: 0.5
                        )
                    }
                }

                // Grid lines (like notebook paper)
                VStack(spacing: 24) {
                    ForEach(0..<50) { _ in
                        Divider()
                            .background(Color.doodleBlue.opacity(0.1))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 20)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hand-drawn Button Style
struct HandDrawnButtonStyle: ButtonStyle {
    var color: Color = .doodleBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("ChalkboardSE-Regular", size: 18))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color)
                    .overlay(
                        // Hand-drawn border effect
                        SketchyRectangle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: color.opacity(0.3), radius: 4, x: 2, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Sketchy Rectangle Shape
struct SketchyRectangle: Shape {
    var roughness: CGFloat = 2.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let points = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        path.move(to: points[0])

        for i in 0..<4 {
            let start = points[i]
            let end = points[(i + 1) % 4]

            // Add slight wobble to lines
            let midPoint = CGPoint(
                x: (start.x + end.x) / 2 + CGFloat.random(in: -roughness...roughness),
                y: (start.y + end.y) / 2 + CGFloat.random(in: -roughness...roughness)
            )

            path.addQuadCurve(to: end, control: midPoint)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Doodle Icons
struct DoodleCoin: View {
    var isHeads: Bool
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // Coin body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.85, blue: 0.5), Color(red: 0.85, green: 0.7, blue: 0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.6, green: 0.5, blue: 0.2), lineWidth: 3)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .offset(x: -2, y: -2)
                        .frame(width: size - 10, height: size - 10)
                )

            // Coin face
            if isHeads {
                // Heads - simple face doodle
                VStack(spacing: 4) {
                    // Eyes
                    HStack(spacing: 20) {
                        Circle()
                            .fill(Color.inkBrown)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.inkBrown)
                            .frame(width: 8, height: 8)
                    }

                    // Smile
                    Path { path in
                        path.move(to: CGPoint(x: -15, y: 0))
                        path.addQuadCurve(
                            to: CGPoint(x: 15, y: 0),
                            control: CGPoint(x: 0, y: 15)
                        )
                    }
                    .stroke(Color.inkBrown, lineWidth: 3)
                    .frame(width: 30, height: 20)
                }
                .offset(y: -5)
            } else {
                // Tails - star doodle
                DoodleStar()
                    .stroke(Color.inkBrown, lineWidth: 3)
                    .frame(width: size * 0.5, height: size * 0.5)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 4, y: 4)
    }
}

// MARK: - Doodle Star
struct DoodleStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4

        var path = Path()
        let points = 5

        for i in 0..<points * 2 {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = Angle.degrees(Double(i) * 360 / Double(points * 2) - 90)
            let point = CGPoint(
                x: center.x + radius * cos(angle.radians),
                y: center.y + radius * sin(angle.radians)
            )

            if i == 0 {
                path.move(to: point)
            } else {
                // Add slight wobble
                let wobbleX = CGFloat.random(in: -1...1)
                let wobbleY = CGFloat.random(in: -1...1)
                path.addLine(to: CGPoint(x: point.x + wobbleX, y: point.y + wobbleY))
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Doodle Decorations
struct DoodleArrow: View {
    var direction: ArrowDirection = .right

    enum ArrowDirection {
        case left, right, up, down
    }

    var body: some View {
        Path { path in
            switch direction {
            case .right:
                path.move(to: CGPoint(x: 0, y: 10))
                path.addLine(to: CGPoint(x: 30, y: 10))
                path.move(to: CGPoint(x: 22, y: 2))
                path.addLine(to: CGPoint(x: 32, y: 10))
                path.addLine(to: CGPoint(x: 22, y: 18))
            case .left:
                path.move(to: CGPoint(x: 32, y: 10))
                path.addLine(to: CGPoint(x: 2, y: 10))
                path.move(to: CGPoint(x: 10, y: 2))
                path.addLine(to: CGPoint(x: 0, y: 10))
                path.addLine(to: CGPoint(x: 10, y: 18))
            case .up:
                path.move(to: CGPoint(x: 10, y: 20))
                path.addLine(to: CGPoint(x: 10, y: 0))
                path.move(to: CGPoint(x: 2, y: 8))
                path.addLine(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 18, y: 8))
            case .down:
                path.move(to: CGPoint(x: 10, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 20))
                path.move(to: CGPoint(x: 2, y: 12))
                path.addLine(to: CGPoint(x: 10, y: 20))
                path.addLine(to: CGPoint(x: 18, y: 12))
            }
        }
        .stroke(Color.inkBrown, lineWidth: 2)
        .frame(width: 32, height: 20)
    }
}

// MARK: - Doodle Sparkle
struct DoodleSparkle: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.highlightYellow)
                    .frame(width: size * 0.15, height: size)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
        }
    }
}

// MARK: - Hand-drawn Text Field Style
struct HandDrawnTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.custom("ChalkboardSE-Regular", size: 16))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.inkGray.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 1, y: 1)
            )
    }
}

// MARK: - Card Style View
struct PaperCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.paperDark, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Shake Hint View
struct ShakeHintView: View {
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 16))

            Text("摇一摇抛硬币")
                .font(.custom("ChalkboardSE-Regular", size: 14))
        }
        .foregroundStyle(Color.inkGray)
        .offset(x: shakeOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                shakeOffset = 5
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        PaperTexture()
        VStack(spacing: 30) {
            HStack(spacing: 40) {
                DoodleCoin(isHeads: true, size: 100)
                DoodleCoin(isHeads: false, size: 100)
            }

            Button("抛硬币") {}
                .buttonStyle(HandDrawnButtonStyle())

            PaperCard {
                VStack {
                    Text("手绘风格卡片")
                        .font(.custom("ChalkboardSE-Regular", size: 18))
                    TextField("输入...", text: .constant(""))
                        .textFieldStyle(HandDrawnTextFieldStyle())
                }
            }
            .padding(.horizontal, 20)

            ShakeHintView()

            HStack {
                DoodleSparkle()
                DoodleArrow(direction: .right)
                DoodleSparkle()
            }
        }
    }
}
