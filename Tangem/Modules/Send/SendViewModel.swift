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

    @Published var currentPageInvalid: Bool = false

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

    // MARK: - Dependencies

    private unowned let coordinator: SendRoutable
    private let sendModel: SendModel
    private var bag: Set<AnyCancellable> = [] // remove?

    init(
        coordinator: SendRoutable
    ) {
        self.coordinator = coordinator
        sendModel = SendModel()
        step = .amount

        $step
            .flatMap { currentStep in
                self.sendModel.stepValid(currentStep)
            }
            .map {
                !$0
            }
            .assign(to: &$currentPageInvalid)

        sendModel.amountText = "100"
        sendModel.destinationText = "0x8C8D7C46219D9205f056f28fee5950aD564d7465"
        sendModel.feeText = "Fast 🐰"
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
}

extension SendViewModel {
    var sendAmountInput: SendAmountInput {
        sendModel
    }

    var sendAmountValidator: SendAmountValidator {
        sendModel
    }

    var sendDestinationInput: SendDestinationInput {
        sendModel
    }

    var sendDestinationValidator: SendDestinationValidator {
        sendModel
    }

    var sendFeeInput: SendFeeInput {
        sendModel
    }

    var sendSummaryInput: SendSummaryInput {
        sendModel
    }
}

extension SendViewModel: SendSummaryRoutable {
    func openStep(step: SendStep) {
        withAnimation(.easeOut(duration: 0.3)) {
            self.step = step
        }
    }

    func send() {
        sendModel.send()
    }
}
