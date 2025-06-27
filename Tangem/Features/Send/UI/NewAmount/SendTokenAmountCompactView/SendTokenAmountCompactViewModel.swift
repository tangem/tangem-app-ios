//
//  SendTokenAmountCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import struct TangemUI.TokenIconInfo

class SendTokenAmountCompactViewModel: ObservableObject, Identifiable {
    let walletNameTitle: String
    let tokenIconInfo: TokenIconInfo

    var tokenCurrencySymbol: String { tokenItem.currencySymbol }

    @Published private(set) var amountTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private(set) var alternativeAmount: String?

    @Published private(set) var balance: LoadableTokenBalanceView.State?

    private let tokenItem: TokenItem
    private let fiatItem: FiatItem
    private let sendAmountFormatter: SendAmountFormatter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory
    private let loadableTokenBalanceViewStateBuilder: LoadableTokenBalanceViewStateBuilder
    private var amountPublisherSubscription: AnyCancellable?
    private var balancePublisherSubscription: AnyCancellable?

    init(receiveToken: SendReceiveToken) {
        walletNameTitle = receiveToken.wallet
        tokenIconInfo = receiveToken.tokenIconInfo
        tokenItem = receiveToken.tokenItem
        fiatItem = receiveToken.fiatItem

        sendAmountFormatter = .init(tokenItem: tokenItem, fiatItem: fiatItem)
        loadableTokenBalanceViewStateBuilder = .init()
        prefixSuffixOptionsFactory = .init()

        amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
        amountTextFieldViewModel = .init(maximumFractionDigits: tokenItem.decimalCount)
    }

    func bind(amountPublisher: AnyPublisher<SendAmount?, Never>) {
        amountPublisherSubscription = amountPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, amount in
                viewModel.updateAmount(from: amount)
            }
    }

    func bind(balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never>) {
        balancePublisherSubscription = balanceTypePublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, type in
                viewModel.balance = viewModel.loadableTokenBalanceViewStateBuilder.build(type: type)
            }
    }

    private func updateAmount(from amount: SendAmount?) {
        alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .crypto)

        switch amount?.type {
        case .typical(let crypto, _):
            amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
            amountTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
            amountTextFieldViewModel.update(value: crypto)
        case .alternative(let fiat, _):
            amountFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: fiatItem.currencyCode)
            amountTextFieldViewModel.update(maximumFractionDigits: fiatItem.fractionDigits)
            amountTextFieldViewModel.update(value: fiat)
        case nil:
            break
        }
    }
}
