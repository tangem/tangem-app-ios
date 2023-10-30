//
//  SendViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: SendStep

    var showBackButton: Bool {
        if case .summary = step {
            return false
        } else {
            return step.previousStep != nil
        }
    }

    var showNextButton: Bool {
        step.nextStep != nil
    }

    var title: String {
        step.name
    }

    var showSendButton: Bool {
        step == .summary
    }

    // MARK: - Dependencies

    private unowned let coordinator: SendRoutable

    init(
        coordinator: SendRoutable
    ) {
        self.coordinator = coordinator
        step = .amount
    }

    func next() {
        if let nextStep = step.nextStep {
            step = nextStep
        }
    }

    func back() {
        if let previousStep = step.previousStep {
            step = previousStep
        }
    }

    func didTapSummary(step: SendStep) {
        self.step = step
    }

    func send() {
        print("send")
    }
}
