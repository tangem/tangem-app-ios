//
//  SendAmountCompactViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SendAmountCompactViewModel: ObservableObject, Identifiable {
    // Use the estimated size as initial value
    @Published var viewSize: CGSize = .init(width: 361, height: 143)
    @Published private(set) var alternativeAmount: String?
    @Published private(set) var amountDecimalNumberTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions

    let tokenIconInfo: TokenIconInfo

    private weak var input: SendAmountInput?
    private let tokenItem: TokenItem
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory

    private var bag: Set<AnyCancellable> = []

    init(
        input: SendAmountInput,
        tokenIconInfo: TokenIconInfo,
        tokenItem: TokenItem
    ) {
        self.input = input
        self.tokenIconInfo = tokenIconInfo
        self.tokenItem = tokenItem

        let prefixSuffixOptionsFactory = SendDecimalNumberTextField.PrefixSuffixOptionsFactory(
            cryptoCurrencyCode: tokenItem.currencySymbol,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode
        )
        self.prefixSuffixOptionsFactory = prefixSuffixOptionsFactory
        _amountFieldOptions = .init(initialValue: prefixSuffixOptionsFactory.makeCryptoOptions())
        amountDecimalNumberTextFieldViewModel = .init(maximumFractionDigits: tokenItem.decimalCount)

        bind(input: input)
    }

    private func bind(input: SendAmountInput) {
        input.amountPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, amount in
                viewModel.updateAmount(from: amount)
                viewModel.updateAlternativeAmount(from: amount)
            }
            .store(in: &bag)
    }

    private func updateAmount(from amount: SendAmount?) {
        switch amount?.type {
        case .typical(let crypto, _):
            amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions()
            amountDecimalNumberTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            amountDecimalNumberTextFieldViewModel.update(value: crypto)
        case .alternative(let fiat, _):
            amountFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions()
            amountDecimalNumberTextFieldViewModel.update(maximumFractionDigits: SendAmountStep.Constants.fiatMaximumFractionDigits)
            amountDecimalNumberTextFieldViewModel.update(value: fiat)
        case nil:
            break
        }
    }

    private func updateAlternativeAmount(from amount: SendAmount?) {
        alternativeAmount = amount?.formatAlternative(
            currencySymbol: tokenItem.currencySymbol,
            decimalCount: tokenItem.decimalCount
        )
    }
}
