//
//  CommonNewOnrampStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class CommonNewOnrampStepsManager {
    private let onrampStep: NewOnrampStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let shouldActivateKeyboard: Bool

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        onrampStep: NewOnrampStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        shouldActivateKeyboard: Bool
    ) {
        self.onrampStep = onrampStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.shouldActivateKeyboard = shouldActivateKeyboard

        stack = [onrampStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func next(step: SendStep) {
        stack.append(step)
        output?.update(step: step)
    }
}

// MARK: - SendStepsManager

extension CommonNewOnrampStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { shouldActivateKeyboard }
    var initialFlowActionType: SendFlowActionType { .onramp }
    var initialStep: any SendStep { onrampStep }

    var shouldShowDismissAlert: Bool {
        return false
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .newOnramp:
            return .init(title: summaryTitleProvider.title, leadingViewType: .closeButton, trailingViewType: .dotsButton { [weak self] in
                self?.onrampStep.openOnrampSettingsView()
            })
        case .finish:
            return .init(leadingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .newOnramp: .init(action: .action)
        case .finish: .init(action: .close)
        default: .empty
        }
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performFinish() {
        next(step: finishStep)
    }
}
