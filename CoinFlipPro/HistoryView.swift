import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Decision.createdAt, order: .reverse)
    private var decisions: [Decision]

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                PaperTexture()

                if decisions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Luck chart
                            luckChartView

                            // Statistics summary
                            statsSummaryView

                            // History list
                            historyListView
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundStyle(Color.inkBrown)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !decisions.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .confirmationDialog("确定要清空所有记录吗?", isPresented: $showClearConfirmation) {
                Button("清空所有记录", role: .destructive) {
                    clearAllDecisions()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            DoodleCoin(isHeads: true, size: 100)
                .opacity(0.5)

            Text("还没有抛过硬币")
                .font(.custom("ChalkboardSE-Bold", size: 22))
                .foregroundStyle(Color.inkBrown)

            Text("开始抛硬币来记录你的决定吧!")
                .font(.custom("ChalkboardSE-Regular", size: 16))
                .foregroundStyle(Color.inkGray)

            Button("开始") {
                dismiss()
            }
            .buttonStyle(HandDrawnButtonStyle())
        }
    }

    // MARK: - Luck Chart View
    private var luckChartView: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("运气曲线")
                    .font(.custom("ChalkboardSE-Bold", size: 18))
                    .foregroundStyle(Color.inkBrown)

                if decisions.count >= 3 {
                    let chartData = getChartData()
                    Chart(chartData) { point in
                        LineMark(
                            x: .value("次数", point.flipNumber),
                            y: .value("幸运率", point.luckRate)
                        )
                        .foregroundStyle(Color.doodleBlue)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                        AreaMark(
                            x: .value("次数", point.flipNumber),
                            y: .value("幸运率", point.luckRate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.doodleBlue.opacity(0.3), Color.doodleBlue.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("次数", point.flipNumber),
                            y: .value("幸运率", point.luckRate)
                        )
                        .foregroundStyle(Color.doodleBlue)
                        .symbolSize(30)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisValueLabel()
                                .font(.custom("ChalkboardSE-Regular", size: 10))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            AxisValueLabel {
                                if let intValue = value.as(Double.self) {
                                    Text("\(Int(intValue))%")
                                        .font(.custom("ChalkboardSE-Regular", size: 10))
                                }
                            }
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 200)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.inkGray.opacity(0.5))

                        Text("再抛 \(3 - decisions.count) 次硬币")
                            .font(.custom("ChalkboardSE-Regular", size: 14))
                            .foregroundStyle(Color.inkGray)

                        Text("就能看到运气曲线了!")
                            .font(.custom("ChalkboardSE-Regular", size: 14))
                            .foregroundStyle(Color.inkGray)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Stats Summary View
    private var statsSummaryView: some View {
        PaperCard {
            VStack(spacing: 16) {
                Text("统计摘要")
                    .font(.custom("ChalkboardSE-Bold", size: 18))
                    .foregroundStyle(Color.inkBrown)

                HStack(spacing: 20) {
                    StatBadge(
                        title: "正面",
                        count: decisions.filter { $0.result }.count,
                        color: .doodleGreen
                    )

                    StatBadge(
                        title: "反面",
                        count: decisions.filter { !$0.result }.count,
                        color: .doodleOrange
                    )

                    StatBadge(
                        title: "总次数",
                        count: decisions.count,
                        color: .doodleBlue
                    )
                }
            }
        }
    }

    // MARK: - History List View
    private var historyListView: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("历史记录")
                    .font(.custom("ChalkboardSE-Bold", size: 18))
                    .foregroundStyle(Color.inkBrown)

                LazyVStack(spacing: 12) {
                    ForEach(decisions.prefix(50)) { decision in
                        DecisionRow(decision: decision)
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func getChartData() -> [LuckDataPoint] {
        let sorted = decisions.sorted { $0.createdAt < $1.createdAt }
        var dataPoints: [LuckDataPoint] = []
        var luckyCount = 0

        for (index, decision) in sorted.enumerated() {
            if decision.isLucky {
                luckyCount += 1
            }
            let rate = Double(luckyCount) / Double(index + 1) * 100
            dataPoints.append(LuckDataPoint(flipNumber: index + 1, luckRate: rate))
        }

        return dataPoints
    }

    private func clearAllDecisions() {
        for decision in decisions {
            modelContext.delete(decision)
        }
        try? modelContext.save()
    }
}

// MARK: - Luck Data Point
struct LuckDataPoint: Identifiable {
    let id = UUID()
    let flipNumber: Int
    let luckRate: Double
}

// MARK: - Stat Badge
struct StatBadge: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.custom("ChalkboardSE-Bold", size: 28))
                .foregroundStyle(color)

            Text(title)
                .font(.custom("ChalkboardSE-Regular", size: 12))
                .foregroundStyle(Color.inkGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Decision Row
struct DecisionRow: View {
    let decision: Decision

    var body: some View {
        HStack(spacing: 12) {
            // Coin icon
            DoodleCoin(isHeads: decision.result, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                if !decision.question.isEmpty {
                    Text(decision.question)
                        .font(.custom("ChalkboardSE-Regular", size: 14))
                        .foregroundStyle(Color.inkBrown)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(decision.resultLabel)
                        .font(.custom("ChalkboardSE-Bold", size: 14))
                        .foregroundStyle(decision.result ? Color.doodleGreen : Color.doodleOrange)

                    Text("→")
                        .foregroundStyle(Color.inkGray)

                    Text(decision.resultText)
                        .font(.custom("ChalkboardSE-Regular", size: 14))
                        .foregroundStyle(Color.inkBrown)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(decision.formattedDate)
                    .font(.custom("ChalkboardSE-Regular", size: 10))
                    .foregroundStyle(Color.inkGray)

                if decision.isLucky {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.highlightYellow)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.paper)
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Decision.self, inMemory: true)
}
