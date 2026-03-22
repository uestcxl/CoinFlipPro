import Foundation
import SwiftUI
import SwiftData
import CoreMotion
import AudioToolbox

@Observable
class CoinFlipViewModel {
    // MARK: - State
    var isFlipping = false
    var flipProgress: Double = 0
    var currentResult: Bool? // true = Heads, false = Tails
    var showResult = false

    // Input state
    var question: String = ""
    var optionA: String = "选项 A"
    var optionB: String = "选项 B"

    // Shake detection
    private let motionManager = CMMotionManager()
    private var shakeThreshold: Double = 2.5
    private var lastShakeTime: Date = Date.distantPast

    // Callback for flip completion
    var onFlipComplete: ((Bool) -> Void)?

    // MARK: - Motion Detection
    func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else { return }
            self.handleAccelerometerData(data.acceleration)
        }
    }

    func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
    }

    private func handleAccelerometerData(_ acceleration: CMAcceleration) {
        let totalAcceleration = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )

        let now = Date()
        let timeSinceLastShake = now.timeIntervalSince(lastShakeTime)

        if totalAcceleration > shakeThreshold && timeSinceLastShake > 1.0 && !isFlipping {
            lastShakeTime = now
            triggerFlip()
        }
    }

    // MARK: - Coin Flip Logic
    func triggerFlip() {
        guard !isFlipping else { return }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        isFlipping = true
        showResult = false
        flipProgress = 0

        // Animate flip
        Task { @MainActor in
            await animateFlip()
        }
    }

    @MainActor
    private func animateFlip() async {
        // Random number of rotations (5-8 full rotations)
        let rotations = Double.random(in: 5...8)
        let duration = 1.5

        // Flip animation
        for i in 0..<60 {
            let progress = Double(i) / 60.0
            flipProgress = progress * rotations

            // Add some easing
            let easedProgress = easeOutCubic(progress)
            flipProgress = easedProgress * rotations

            try? await Task.sleep(for: .milliseconds(duration * 1000 / 60))
        }

        // Determine result (random)
        let result = Bool.random()
        currentResult = result
        isFlipping = false
        showResult = true

        // Final haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Play sound
        AudioServicesPlaySystemSound(1104)

        // Callback
        onFlipComplete?(result)
    }

    private func easeOutCubic(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }

    // MARK: - Decision Saving
    func saveDecision(context: ModelContext, result: Bool) {
        let decision = Decision(
            question: question.isEmpty ? "随机抛硬币" : question,
            optionA: optionA,
            optionB: optionB,
            result: result
        )
        context.insert(decision)
        try? context.save()
    }

    // MARK: - Statistics
    static func calculateLuckRate(decisions: [Decision]) -> Double {
        guard !decisions.isEmpty else { return 0.5 }
        let luckyCount = decisions.filter { $0.isLucky }.count
        return Double(luckyCount) / Double(decisions.count)
    }

    static func getStreak(decisions: [Decision]) -> Int {
        guard !decisions.isEmpty else { return 0 }

        var streak = 0
        let sorted = decisions.sorted { $0.createdAt > $1.createdAt }

        guard let firstResult = sorted.first?.isLucky else { return 0 }

        for decision in sorted {
            if decision.isLucky == firstResult {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }
}
