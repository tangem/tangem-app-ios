//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendSummaryViewModelInput: AnyObject {
    var amountText: String { get }
    var canEditAmount: Bool { get }
    var canEditDestination: Bool { get }

    var destinationTextBinding: Binding<String> { get }
    var feeText: AnyPublisher<String?, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }

    func send()
}

class SendSummaryViewModel: ObservableObject {
    let canEditAmount: Bool
    let canEditDestination: Bool

    let amountText: String
    let destinationText: String

    @Published var isSending = false
    @Published var feeText: String = ""

    weak var router: SendSummaryRoutable?

    private var bag: Set<AnyCancellable> = []
    private weak var input: SendSummaryViewModelInput?

    init(input: SendSummaryViewModelInput) {
        amountText = input.amountText

        canEditAmount = input.canEditAmount
        canEditDestination = input.canEditDestination

        destinationText = input.destinationTextBinding.wrappedValue

        self.input = input

        bind(from: input)
    }

    func didTapSummary(for step: SendStep) {
        router?.openStep(step)
    }

    func send() {
        input?.send()
    }

    private func bind(from input: SendSummaryViewModelInput) {
        input
            .isSending
            .assign(to: \.isSending, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .feeText
            .map {
                $0 ?? ""
            }
            .assign(to: \.feeText, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
