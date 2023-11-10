//
//  SendAmountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

protocol SendAmountViewModelInput {
    var amountTextBinding: Binding<String> { get }
    var amountError: AnyPublisher<Error?, Never> { get }
}

protocol SendAmountViewModelDelegate: AnyObject {
    func didTapMaxAmount()
}

class SendAmountViewModel: ObservableObject {
    var amountText: Binding<String>

    @Published var amountError: String?

    weak var delegate: SendAmountViewModelDelegate?

    private var bag: Set<AnyCancellable> = []

    init(input: SendAmountViewModelInput) {
        amountText = input.amountTextBinding

        bind(from: input)
    }

    func didTapMaxAmount() {
        delegate?.didTapMaxAmount()
    }

    private func bind(from input: SendAmountViewModelInput) {
        input
            .amountError
            .map { $0?.localizedDescription }
            .assign(to: \.amountError, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
