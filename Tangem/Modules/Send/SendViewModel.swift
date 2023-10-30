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

    @Published var amountText: String = "100,00 USDT"
    @Published var destination: String = "0x8C8D7C46219D9205f056f28fee5950aD564d7465"
    @Published var fee: String = "Fast 🐰"

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
//            withAnimation() {
                step = nextStep
//            }
        }
    }

    func back() {
        if let previousStep = step.previousStep {
            withAnimation(.easeOut) {
                step = previousStep
            }
        }
    }

    func didTapSummary(step: SendStep) {
        withAnimation(.easeOut(duration: 0.15)) {
            self.step = step
        }
    }

    func send() {
        print("send")
    }
}
