//
//  SendAmountCompactTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import TangemUI

final class SendAmountCompactTokenViewModel: ObservableObject, Identifiable {
    let title: Title
    let tokenIconInfo: TokenIconInfo
    var tokenCurrencySymbol: String { tokenItem.currencySymbol }

    var formattedAmount: String? {
        switch amount?.type {
        case .none:
            return nil
        case _ where isApproximateAmount:
            return "\(AppConstants.tildeSign) \(sendAmountFormatter.formatMain(amount: amount))"
        case _:
            return sendAmountFormatter.formatMain(amount: amount)
        }
    }

    var formattedAlternativeAmount: String? {
        switch amount?.type {
        case .none:
            return nil
        case .typical:
            return sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .crypto)
        case .alternative:
            return sendAmountFormatter.formattedAlternative(sendAmount: amount, type: .fiat)
        }
    }

    @Published private var amount: SendAmount? = nil
    @Published private var isApproximateAmount: Bool = false

    @Published private(set) var highPriceImpactWarning: HighPriceImpactWarning?
    @Published private(set) var balance: LoadableBalanceView.State?

    private let tokenItem: TokenItem
    private let fiatItem: FiatItem
    private let sendAmountFormatter: SendAmountFormatter
    private let loadableTokenBalanceViewStateBuilder: LoadableBalanceViewStateBuilder
    private let tokenIconInfoBuilder = TokenIconInfoBuilder()

    convenience init(receiveToken: SendReceiveToken) {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let tokenIconInfo = tokenIconInfoBuilder.build(from: receiveToken.tokenItem, isCustom: receiveToken.isCustom)

        self.init(
            title: .text(Localization.sendWithSwapRecipientAmountTitle),
            tokenIconInfo: tokenIconInfo,
            tokenItem: receiveToken.tokenItem,
            fiatItem: receiveToken.fiatItem
        )
    }

    convenience init(sourceToken: SendSourceToken, actionType: SendFlowActionType) {
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let tokenIconInfo = tokenIconInfoBuilder.build(from: sourceToken.tokenItem, isCustom: sourceToken.isCustom)

        self.init(
            title: .header(sourceToken.header.asSendTokenHeader(actionType: actionType)),
            tokenIconInfo: tokenIconInfo,
            tokenItem: sourceToken.tokenItem,
            fiatItem: sourceToken.fiatItem
        )
    }

    init(
        title: Title,
        tokenIconInfo: TokenIconInfo,
        tokenItem: TokenItem,
        fiatItem: FiatItem
    ) {
        self.title = title
        self.tokenIconInfo = tokenIconInfo
        self.tokenItem = tokenItem
        self.fiatItem = fiatItem

        sendAmountFormatter = .init(tokenItem: tokenItem, fiatItem: fiatItem)
        loadableTokenBalanceViewStateBuilder = .init()
    }

    func bind(amountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never>) {
        amountPublisher
            // Ignore non-amount cases
            .compactMap { $0.value }
            .receiveOnMain()
            .assign(to: &$amount)
    }

    func bind(isApproximateAmountPublisher: AnyPublisher<Bool, Never>) {
        isApproximateAmountPublisher
            .receiveOnMain()
            .assign(to: &$isApproximateAmount)
    }

    func bind(balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never>) {
        balanceTypePublisher
            .withWeakCaptureOf(self)
            .map { $0.loadableTokenBalanceViewStateBuilder.build(type: $1) }
            .receiveOnMain()
            .assign(to: &$balance)
    }

    func bind(highPriceImpactPublisher: AnyPublisher<HighPriceImpactCalculator.Result?, Never>) {
        highPriceImpactPublisher.map { result in
            result.map { HighPriceImpactWarning($0) }
        }
        .receiveOnMain()
        .assign(to: &$highPriceImpactWarning)
    }
}

// MARK: - Types

extension SendAmountCompactTokenViewModel {
    enum Title {
        case text(String)
        case header(SendTokenHeader)
    }

    struct HighPriceImpactWarning {
        let percent: String
        let infoMessage: String
        let level: Level

        init(_ result: HighPriceImpactCalculator.Result) {
            percent = result.lossesInPercentsFormatted
            infoMessage = result.infoMessage

            switch result.level {
            case .negligible: level = .negligible
            case .warningLoss: level = .warningLoss
            case .highLossLowAmount: level = .highLossLowAmount
            case .highLossHighAmount: level = .highLossHighAmount
            }
        }

        enum Level {
            case negligible
            case warningLoss
            case highLossLowAmount
            case highLossHighAmount
        }
    }
}
