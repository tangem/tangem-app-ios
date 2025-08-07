//
//  SendNewAmountCompactTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemFoundation
import struct TangemUI.TokenIconInfo
import struct TangemUIUtils.AlertBinder

class SendNewAmountCompactTokenViewModel: ObservableObject, Identifiable {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let walletNameTitle: String
    let tokenIconInfo: TokenIconInfo

    var tokenCurrencySymbol: String { tokenItem.currencySymbol }

    @Published private(set) var amountTextFieldViewModel: DecimalNumberTextField.ViewModel
    @Published private(set) var amountFieldOptions: SendDecimalNumberTextField.PrefixSuffixOptions
    @Published private(set) var alternativeAmount: String?
    @Published private(set) var highPriceImpactWarning: HighPriceImpactWarning?

    @Published private(set) var balance: LoadableTokenBalanceView.State?

    private let tokenItem: TokenItem
    private let fiatItem: FiatItem
    private let sendAmountFormatter: SendAmountFormatter
    private let prefixSuffixOptionsFactory: SendDecimalNumberTextField.PrefixSuffixOptionsFactory
    private let loadableTokenBalanceViewStateBuilder: LoadableTokenBalanceViewStateBuilder
    private var amountPublisherSubscription: AnyCancellable?
    private var balancePublisherSubscription: AnyCancellable?

    convenience init(receiveToken: SendReceiveToken) {
        self.init(
            wallet: receiveToken.wallet,
            tokenIconInfo: receiveToken.tokenIconInfo,
            tokenItem: receiveToken.tokenItem,
            fiatItem: receiveToken.fiatItem
        )
    }

    convenience init(sourceToken: SendSourceToken) {
        self.init(
            wallet: sourceToken.wallet,
            tokenIconInfo: sourceToken.tokenIconInfo,
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem
        )
    }

    init(wallet: String, tokenIconInfo: TokenIconInfo, tokenItem: TokenItem, fiatItem: FiatItem) {
        walletNameTitle = wallet
        self.tokenIconInfo = tokenIconInfo
        self.tokenItem = tokenItem
        self.fiatItem = fiatItem

        sendAmountFormatter = .init(tokenItem: tokenItem, fiatItem: fiatItem)
        loadableTokenBalanceViewStateBuilder = .init()
        prefixSuffixOptionsFactory = .init()

        amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
        amountTextFieldViewModel = .init(maximumFractionDigits: tokenItem.decimalCount)
    }

    func bind(amountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never>) {
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

    func bind(highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never>) {
        highPriceImpactPublisher.map { result in
            if let result, result.isHighPriceImpact {
                return HighPriceImpactWarning(percent: result.lossesInPercentsFormatted, infoMessage: result.infoMessage)
            }

            return nil
        }
        .receiveOnMain()
        .assign(to: &$highPriceImpactWarning)
    }

    func userDidTapHighPriceImpactWarning(highPriceImpactWarning: HighPriceImpactWarning) {
        alertPresenter.present(alert: .init(title: "", message: highPriceImpactWarning.infoMessage))
    }

    private func updateAmount(from amount: LoadingResult<SendAmount, Error>) {
        switch amount {
        case .loading, .failure:
            // Do nothing. Just leave a current amount on UI
            break

        case .success(let amount):
            switch amount.type {
            case .typical(let crypto, _):
                amountFieldOptions = prefixSuffixOptionsFactory.makeCryptoOptions(cryptoCurrencyCode: tokenItem.currencySymbol)
                amountTextFieldViewModel.update(maximumFractionDigits: tokenItem.decimalCount)
                amountTextFieldViewModel.update(value: crypto)
                alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .crypto)
            case .alternative(let fiat, _):
                amountFieldOptions = prefixSuffixOptionsFactory.makeFiatOptions(fiatCurrencyCode: fiatItem.currencyCode)
                amountTextFieldViewModel.update(maximumFractionDigits: fiatItem.fractionDigits)
                amountTextFieldViewModel.update(value: fiat)
                alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .fiat)
            }
        }
    }
}

extension SendNewAmountCompactTokenViewModel {
    struct HighPriceImpactWarning {
        let percent: String
        let infoMessage: String
    }
}
