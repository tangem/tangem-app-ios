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

    let title: String
    let tokenIconInfo: TokenIconInfo

    var tokenCurrencySymbol: String { tokenItem.currencySymbol }

    @Published private(set) var amountText: String = ""
    @Published private(set) var alternativeAmount: String?
    @Published private(set) var highPriceImpactWarning: HighPriceImpactWarning?

    @Published private(set) var balance: LoadableTokenBalanceView.State?

    private let isApproximateAmount: Bool
    private let tokenItem: TokenItem
    private let fiatItem: FiatItem
    private let sendAmountFormatter: SendAmountFormatter
    private let loadableTokenBalanceViewStateBuilder: LoadableTokenBalanceViewStateBuilder
    private var amountPublisherSubscription: AnyCancellable?
    private var balancePublisherSubscription: AnyCancellable?

    convenience init(receiveToken: SendReceiveToken) {
        self.init(
            title: Localization.sendWithSwapRecipientAmountTitle,
            tokenIconInfo: receiveToken.tokenIconInfo,
            tokenItem: receiveToken.tokenItem,
            fiatItem: receiveToken.fiatItem,
            isApproximateAmount: true
        )
    }

    convenience init(sourceToken: SendSourceToken) {
        self.init(
            title: Localization.sendFromWalletName(sourceToken.wallet),
            tokenIconInfo: sourceToken.tokenIconInfo,
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem,
            isApproximateAmount: false
        )
    }

    init(
        title: String,
        tokenIconInfo: TokenIconInfo,
        tokenItem: TokenItem,
        fiatItem: FiatItem,
        isApproximateAmount: Bool
    ) {
        self.title = title
        self.tokenIconInfo = tokenIconInfo
        self.tokenItem = tokenItem
        self.fiatItem = fiatItem
        self.isApproximateAmount = isApproximateAmount

        sendAmountFormatter = .init(tokenItem: tokenItem, fiatItem: fiatItem)
        loadableTokenBalanceViewStateBuilder = .init()
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
            result.map { result in
                HighPriceImpactWarning(
                    percent: result.lossesInPercentsFormatted,
                    infoMessage: result.infoMessage,
                    isHighPriceImpact: result.isHighPriceImpact
                )
            }
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
            case .typical where isApproximateAmount:
                amountText = "\(AppConstants.tildeSign) \(sendAmountFormatter.formatMain(amount: amount))"
                alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .crypto)
            case .typical:
                amountText = sendAmountFormatter.formatMain(amount: amount)
                alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .crypto)
            case .alternative where isApproximateAmount:
                amountText = "\(AppConstants.tildeSign) \(sendAmountFormatter.formatMain(amount: amount))"
                alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .fiat)
            case .alternative:
                amountText = sendAmountFormatter.formatMain(amount: amount)
                alternativeAmount = sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .fiat)
            }
        }
    }
}

extension SendNewAmountCompactTokenViewModel {
    struct HighPriceImpactWarning {
        let percent: String
        let infoMessage: String
        let isHighPriceImpact: Bool
    }
}
