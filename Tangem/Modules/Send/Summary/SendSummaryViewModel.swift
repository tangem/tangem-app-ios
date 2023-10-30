//
//  SendSummaryViewModel.swift
//  Send
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

protocol SendSummaryInput {
    var amountText: String { get }
    var destinationText: String { get }
    var feeText: String { get }

//    func send()
}

protocol SendSummaryRoutable {
    func openStep(step: SendStep)
    func send()
}

class SendSummaryViewModel {
    let input: SendSummaryInput
    let router: SendSummaryRoutable

    init(input: SendSummaryInput, router: SendSummaryRoutable) {
        self.input = input
        self.router = router
    }

    func didTapSummary(step: SendStep) {
        router.openStep(step: step)
    }

    func send() {
        router.send()
    }
}
