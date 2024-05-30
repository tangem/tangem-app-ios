//
//  WelcomeOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class WelcomeOnboardingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var viewState: ViewState? = nil

    var currentStep: WelcomeOnbordingStep {
        steps[currentStepIndex]
    }

    // MARK: - Dependencies

    private weak var coordinator: WelcomeOnboardingRoutable?

    private let steps: [WelcomeOnbordingStep]
    private var currentStepIndex = 0

    init(
        steps: [WelcomeOnbordingStep],
        coordinator: WelcomeOnboardingRoutable
    ) {
        self.steps = steps
        self.coordinator = coordinator
        updateState()
    }

    private func updateState() {
        guard currentStepIndex < steps.count else {
            return
        }

        viewState = steps[currentStepIndex].makeViewState(with: self)
    }
}

// MARK: - WelcomeOnbordingStep+

private extension WelcomeOnbordingStep {
    func makeViewState(with routable: WelcomeOnboardingStepRoutable) -> WelcomeOnboardingViewModel.ViewState {
        switch self {
        case .tos:
            return .tos(TOSStepViewModel(routable: routable))
        case .pushNotifications:
            return .pushNotifications(PushNotificationsStepViewModel(routable: routable))
        }
    }
}

// MARK: - ViewState

extension WelcomeOnboardingViewModel {
    enum ViewState: Equatable {
        case tos(TOSStepViewModel)
        case pushNotifications(PushNotificationsStepViewModel)

        static func == (lhs: WelcomeOnboardingViewModel.ViewState, rhs: WelcomeOnboardingViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.tos, .tos), (.pushNotifications, .pushNotifications):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - WelcomeOnboardingStepRoutable

extension WelcomeOnboardingViewModel: WelcomeOnboardingStepRoutable {
    func openNextStep() {
        let nextStepIndex = currentStepIndex + 1

        guard nextStepIndex < steps.count else {
            coordinator?.dismiss()
            return
        }

        currentStepIndex = nextStepIndex
        updateState()
    }
}
