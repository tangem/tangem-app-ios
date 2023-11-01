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

    @Published var currentStepInvalid: Bool = false

    var showNavigationButtons: Bool {
        step.hasNavigationButtons
    }

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

    let sendModel: SendModel

    private unowned let coordinator: SendRoutable
    private var bag: Set<AnyCancellable> = [] // remove?

    private var currentStepValid: AnyPublisher<Bool, Never> {
        $step
            .flatMap { [weak self] step in
                guard let self else {
                    return Just(true).eraseToAnyPublisher() // [REDACTED_TODO_COMMENT]
                }

                switch step {
                case .amount:
                    return sendModel.amountError
                        .map {
                            $0 == nil
                        }
                        .eraseToAnyPublisher()
                case .destination:
                    return Publishers.CombineLatest(sendModel.destinationError, sendModel.destinationAdditionalFieldError)
                        .map {
                            $0 == nil && $1 == nil
                        }
                        .eraseToAnyPublisher()
                default:
                    // [REDACTED_TODO_COMMENT]
                    return Just(true)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    init(
        coordinator: SendRoutable
    ) {
        self.coordinator = coordinator
        sendModel = SendModel()
        step = .amount

        currentStepValid
            .map {
                !$0
            }
            .assign(to: &$currentStepInvalid)

        sendModel.amountText = "100"
        sendModel.destinationText = "0x8C8D7C46219D9205f056f28fee5950aD564d7465"
        sendModel.feeText = "Fast 🐰"
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
