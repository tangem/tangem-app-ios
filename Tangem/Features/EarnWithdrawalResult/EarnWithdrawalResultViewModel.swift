//
//  EarnWithdrawalResultViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class EarnWithdrawalResultViewModel {
    typealias StateModel = EarnWithdrawalResultContentView.StateModel
    typealias Action = EarnWithdrawalResultContentView.Action

    let state: StateModel

    private let transactionURL: URL?
    private weak var router: EarnWithdrawalResultRoutable?

    init(
        input: Input,
        router: EarnWithdrawalResultRoutable?,
        formatFiatAmount: (Decimal, String) -> String? = EarnWithdrawalResultViewModel.formatFiatAmount,
        feeFormatter: FeeFormatter = CommonFeeFormatter(),
        dateFormatter: DateFormatter = EarnWithdrawalResultViewModel.makeDateFormatter()
    ) {
        let tokenItem = input.tokenItem
        let amount = SendCryptoValueFormatter(decimals: tokenItem.decimalCount, currencySymbol: tokenItem.currencySymbol, trimFractions: true)
            .string(from: input.amount)

        let fiatAmount = tokenItem.currencyId.flatMap { formatFiatAmount(input.amount, $0) }

        let feeComponents = feeFormatter.formattedFeeComponents(fee: input.feeAmount, tokenItem: input.feeTokenItem)
        let fee = if let fiatFee = feeComponents.fiatFee {
            EarnWithdrawalResultContentView.Fee(symbol: input.feeTokenItem.currencySymbol, value: fiatFee)
        } else {
            EarnWithdrawalResultContentView.Fee(symbol: nil, value: feeComponents.cryptoFee)
        }

        state = StateModel(
            status: input.status,
            title: Self.title(status: input.status, amount: amount),
            summary: [fiatAmount, dateFormatter.string(from: input.sentDate)].compactMap { $0 }.joined(separator: " · "),
            withdrawalPeriod: input.withdrawalPeriod,
            fee: fee,
            hasTransactionLink: input.transactionURL != nil
        )

        transactionURL = input.transactionURL
        self.router = router
    }

    func handle(_ action: Action) {
        switch action {
        case .explore:
            guard let transactionURL else { return }
            router?.openExplorer(url: transactionURL)
        case .share:
            guard let transactionURL else { return }
            router?.openShareSheet(url: transactionURL)
        case .done:
            router?.closeWithdrawalResult()
        }
    }

    static func formatFiatAmount(_ amount: Decimal, currencyId: String) -> String? {
        BalanceConverter()
            .convertToFiat(amount, currencyId: currencyId)
            .map { BalanceFormatter().formatFiatBalance($0) }
    }

    static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Input

extension EarnWithdrawalResultViewModel {
    struct Input {
        let status: EarnWithdrawalResultContentView.Status
        let tokenItem: TokenItem
        let amount: Decimal
        let sentDate: Date
        let withdrawalPeriod: String
        let feeTokenItem: TokenItem
        let feeAmount: Decimal
        let transactionURL: URL?
    }
}

// MARK: - Private

// [REDACTED_TODO_COMMENT]
private extension EarnWithdrawalResultViewModel {
    static func title(status: EarnWithdrawalResultContentView.Status, amount: String) -> String {
        switch status {
        case .withdrawn: "Withdrawn \(amount)"
        case .inProgress: "Withdrawal in progress\n\(amount)"
        }
    }
}
