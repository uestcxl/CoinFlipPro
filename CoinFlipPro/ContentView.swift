import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CoinFlipViewModel()
    @State private var showHistory = false
    @State private var showSavedConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Paper texture background
                PaperTexture()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header with doodle decorations
                        headerView

                        // Coin display area
                        coinAreaView

                        // Decision input area
                        decisionInputView

                        // Flip button
                        flipButtonView

                        // Shake hint
                        ShakeHintView()

                        // Statistics
                        statsView

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.inkBrown)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
            .onAppear {
                viewModel.startMotionDetection()
            }
            .onDisappear {
                viewModel.stopMotionDetection()
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            DoodleSparkle(size: 24)
            VStack(spacing: 4) {
                Text("Coin Flip Pro")
                    .font(.custom("ChalkboardSE-Bold", size: 32))
                    .foregroundStyle(Color.inkBrown)

                Text("让硬币帮你做决定")
                    .font(.custom("ChalkboardSE-Regular", size: 14))
                    .foregroundStyle(Color.inkGray)
            }
            DoodleSparkle(size: 24)
        }
    }

    // MARK: - Coin Area View
    private var coinAreaView: some View {
        PaperCard {
            VStack(spacing: 20) {
                ZStack {
                    // Coin with flip animation
                    Group {
                        if viewModel.isFlipping {
                            flippingCoin
                        } else if let result = viewModel.currentResult, viewModel.showResult {
                            resultCoin(result: result)
                        } else {
                            defaultCoin
                        }
                    }
                    .frame(height: 160)

                    // Doodle decorations
                    if viewModel.showResult {
                        DoodleSparkle(size: 30)
                            .offset(x: -80, y: -60)

                        DoodleSparkle(size: 20)
                            .offset(x: 75, y: -50)

                        DoodleSparkle(size: 25)
                            .offset(x: -70, y: 55)
                    }
                }

                // Result text
                if let result = viewModel.currentResult, viewModel.showResult {
                    VStack(spacing: 8) {
                        Text(result ? "正面!" : "反面!")
                            .font(.custom("ChalkboardSE-Bold", size: 28))
                            .foregroundStyle(result ? Color.doodleGreen : Color.doodleOrange)

                        if !viewModel.question.isEmpty || viewModel.optionA != "选项 A" {
                            Text("结果: \(result ? viewModel.optionA : viewModel.optionB)")
                                .font(.custom("ChalkboardSE-Regular", size: 18))
                                .foregroundStyle(Color.inkBrown)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Coin States
    private var defaultCoin: some View {
        DoodleCoin(isHeads: true, size: 140)
            .overlay(
                Text("?")
                    .font(.custom("ChalkboardSE-Bold", size: 48))
                    .foregroundStyle(Color.inkBrown.opacity(0.3))
            )
    }

    private var flippingCoin: some View {
        ZStack {
            // Show alternating heads/tails during flip
            let progress = viewModel.flipProgress.truncatingRemainder(dividingBy: 2)
            let showHeads = progress < 1

            DoodleCoin(isHeads: showHeads, size: 140)
                .rotation3DEffect(
                    .degrees(viewModel.flipProgress * 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .scaleEffect(x: abs(cos(Angle.degrees(viewModel.flipProgress * 180).radians)), y: 1)
        }
    }

    private func resultCoin(result: Bool) -> some View {
        DoodleCoin(isHeads: result, size: 140)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Decision Input View
    private var decisionInputView: some View {
        PaperCard {
            VStack(spacing: 16) {
                Text("你在纠结什么?")
                    .font(.custom("ChalkboardSE-Bold", size: 18))
                    .foregroundStyle(Color.inkBrown)

                TextField("输入你的问题（可选）", text: $viewModel.question)
                    .textFieldStyle(HandDrawnTextFieldStyle())

                HStack(spacing: 12) {
                    VStack {
                        Text("正面")
                            .font(.custom("ChalkboardSE-Regular", size: 12))
                            .foregroundStyle(Color.doodleGreen)
                        TextField("选项 A", text: $viewModel.optionA)
                            .textFieldStyle(HandDrawnTextFieldStyle())
                            .frame(width: 120)
                    }

                    DoodleArrow(direction: .right)

                    VStack {
                        Text("反面")
                            .font(.custom("ChalkboardSE-Regular", size: 12))
                            .foregroundStyle(Color.doodleOrange)
                        TextField("选项 B", text: $viewModel.optionB)
                            .textFieldStyle(HandDrawnTextFieldStyle())
                            .frame(width: 120)
                    }
                }
            }
        }
    }

    // MARK: - Flip Button View
    private var flipButtonView: some View {
        Button {
            flipAndSave()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                Text("抛硬币")
                    .font(.custom("ChalkboardSE-Bold", size: 20))
            }
        }
        .buttonStyle(HandDrawnButtonStyle(color: .doodleBlue))
        .disabled(viewModel.isFlipping)
        .opacity(viewModel.isFlipping ? 0.6 : 1)
    }

    // MARK: - Stats View
    @Query(sort: \Decision.createdAt, order: .reverse)
    private var decisions: [Decision]

    private var statsView: some View {
        PaperCard {
            HStack(spacing: 30) {
                StatItem(
                    title: "总次数",
                    value: "\(decisions.count)",
                    icon: "number",
                    color: .doodleBlue
                )

                StatItem(
                    title: "幸运率",
                    value: String(format: "%.0f%%", CoinFlipViewModel.calculateLuckRate(decisions: decisions) * 100),
                    icon: "star.fill",
                    color: .highlightYellow.opacity(0.8)
                )

                StatItem(
                    title: "连胜",
                    value: "\(CoinFlipViewModel.getStreak(decisions: decisions))",
                    icon: "flame.fill",
                    color: .doodleOrange
                )
            }
        }
    }

    // MARK: - Actions
    private func flipAndSave() {
        viewModel.onFlipComplete = { result in
            // Save the decision
            viewModel.saveDecision(context: modelContext, result: result)

            // Show confirmation
            showSavedConfirmation = true

            // Hide after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSavedConfirmation = false
            }
        }

        viewModel.triggerFlip()
    }
}

// MARK: - Stat Item View
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.custom("ChalkboardSE-Bold", size: 24))
                .foregroundStyle(Color.inkBrown)

            Text(title)
                .font(.custom("ChalkboardSE-Regular", size: 12))
                .foregroundStyle(Color.inkGray)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Decision.self, inMemory: true)
}
