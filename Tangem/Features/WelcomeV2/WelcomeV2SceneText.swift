//
//  WelcomeV2SceneText.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WelcomeV2SceneText: View {
    let scene: WelcomeV2Scene
    let isActive: Bool

    @State private var phase = LineRevealPhase.hidden
    /// Guards against a delayed exit reset touching a newer transition.
    @State private var generation = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        text
            .lineSpacing(DesignSystem.Font.headingMediumToken.lineSpacing)
            .lineReveal(phase: phase, timing: Constants.timing, reduceMotion: reduceMotion)
            .onAppear {
                if isActive {
                    reveal(after: Constants.initialDelay)
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    reveal(after: Constants.timing.exitDuration)
                } else {
                    dismiss()
                }
            }
    }

    /// One Text so title and subtitle lines cascade as a single sequence.
    private var text: Text {
        var title = AttributedString(scene.title)
        title.setFontStyle(DesignSystem.Font.headingMediumToken)
        title.foregroundColor = DesignSystem.Color.textStaticDarkPrimary

        var subtitle = AttributedString("\n" + scene.subtitle)
        subtitle.setFontStyle(DesignSystem.Font.headingMediumToken)
        subtitle.foregroundColor = DesignSystem.Color.textStaticDarkSecondary

        return Text(title + subtitle)
    }

    private func reveal(after delay: TimeInterval) {
        generation += 1
        withAnimation(.linear(duration: Constants.timing.enterDuration).delay(delay)) {
            phase = LineRevealPhase.visible
        }
    }

    private func dismiss() {
        generation += 1
        let token = generation
        let exit = Animation.linear(duration: Constants.timing.exitDuration)

        if #available(iOS 17.0, *) {
            withAnimation(exit) {
                phase = LineRevealPhase.gone
            } completion: {
                resetBelow(if: token)
            }
        } else {
            withAnimation(exit) {
                phase = LineRevealPhase.gone
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.timing.exitDuration) {
                resetBelow(if: token)
            }
        }
    }

    private func resetBelow(if token: Int) {
        guard token == generation else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            phase = LineRevealPhase.hidden
        }
    }
}

// MARK: - Constants

private extension WelcomeV2SceneText {
    enum Constants {
        static let timing = LineRevealTiming()
        static let initialDelay: TimeInterval = 0.3
    }
}
