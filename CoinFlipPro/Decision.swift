import Foundation
import SwiftData

@Model
final class Decision {
    var id: UUID
    var question: String
    var optionA: String
    var optionB: String
    var result: Bool // true = 正面(Heads), false = 反面(Tails)
    var createdAt: Date
    var isLucky: Bool // 是否"运气好"（正面的结果）

    init(question: String, optionA: String, optionB: String, result: Bool) {
        self.id = UUID()
        self.question = question
        self.optionA = optionA
        self.optionB = optionB
        self.result = result
        self.createdAt = Date()
        // 默认正面为"幸运"
        self.isLucky = result
    }

    var resultText: String {
        result ? optionA : optionB
    }

    var resultLabel: String {
        result ? "正面" : "反面"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: createdAt)
    }
}
