//
//  TangemPayTransactionDetailsRedesignedMapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPay

struct TangemPayTransactionDetailsRedesignedMapper {
    private let dateFormatter = DateFormatter(dateFormat: "MMM d yyyy")
    private let amountFormatter: TangemPayFiatAmountFormatter

    init(amountFormatter: TangemPayFiatAmountFormatter = .init()) {
        self.amountFormatter = amountFormatter
    }

    func map(spend input: TangemPaySpendDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        let merchantName = input.enrichedMerchantName
            ?? input.merchantName
            ?? Localization.tangempayCardDetailsTitle

        let amount = input.formattedAmount(using: amountFormatter)
        let foreignAmount = input.formattedLocalAmount(using: amountFormatter)
        let amountSubtitle = foreignAmount.map { "\($0) \(AppConstants.dotSign) \(merchantName)" } ?? merchantName

        let category = input.merchantCategory?.nilIfEmpty
            ?? input.enrichedMerchantCategory?.nilIfEmpty
            ?? Localization.tangemPayOther

        var rows: [TangemPayTransactionDetailsDisplayModel.Row] = []
        rows.append(.init(title: Localization.tangemPayTransactionDetailsCategory, value: category))
        if let mcc = input.merchantCategoryCode?.nilIfEmpty {
            rows.append(.init(title: Localization.tangemPayTransactionDetailsMcc, value: mcc))
        }

        return .init(
            headerTitle: Localization.tangemPayPurchase,
            headerSubtitle: formatDateTime(input.transactionDate),
            icon: .merchantLogo(input.enrichedMerchantIcon),
            amount: amount,
            amountSubtitle: amountSubtitle,
            status: status(for: input.status, declinedReason: input.declinedReason),
            rows: rows,
            mainButtonAction: .dispute
        )
    }

    func map(collateral input: TangemPayCollateralDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        .init(
            headerTitle: input.isOutgoing ? Localization.tangemPayWithdrawal : Localization.tangemPayDeposit,
            headerSubtitle: formatDateTime(input.postedAt),
            icon: input.isOutgoing ? .withdrawal : .deposit,
            amount: amountFormatter.formatSigned(input.amount, currencyCode: AppConstants.usdCurrencyCode),
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        )
    }

    func map(payment input: TangemPayPaymentDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        .init(
            headerTitle: Localization.tangemPayWithdrawal,
            headerSubtitle: formatDateTime(input.postedAt),
            icon: .withdrawal,
            amount: amountFormatter.format(-input.amount, currencyCode: input.currency),
            amountSubtitle: nil,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.commonTransfer)],
            mainButtonAction: .info
        )
    }

    func map(fee input: TangemPayFeeDisplayInput) -> TangemPayTransactionDetailsDisplayModel {
        .init(
            headerTitle: Localization.tangemPayFeeTitle,
            headerSubtitle: formatDateTime(input.postedAt),
            icon: .fee,
            amount: amountFormatter.format(-input.amount, currencyCode: input.currency),
            amountSubtitle: input.description?.nilIfEmpty,
            status: nil,
            rows: [.init(title: Localization.tangemPayTransactionDetailsCategory, value: Localization.tangemPayFeeSubtitle)],
            mainButtonAction: .dispute
        )
    }

    func map(cashback: TangemPayTransactionCashback?) -> TangemPayTransactionDetailsViewModel.CashbackRowState {
        guard let cashback else {
            return .loaded(.init(value: .text(Localization.tangemPayTransactionDetailsCashbackNone), subvalue: nil))
        }

        switch cashback {
        case .earned(let amount, let currency, let capTrimmed):
            let subvalue: String? = if amount < 0 {
                Localization.tangemPayTransactionDetailsCashbackRefund
            } else if capTrimmed {
                Localization.tangemPayTransactionDetailsCashbackCapReached
            } else {
                nil
            }

            return .loaded(
                .init(
                    value: .amount(amountFormatter.formatSigned(amount, currencyCode: currency)),
                    subvalue: subvalue
                )
            )

        case .excluded(let reason):
            return .loaded(
                .init(
                    value: .text(Localization.tangemPayTransactionDetailsCashbackNone),
                    subvalue: reason.map(Self.description)
                )
            )

        case .awaitingCalculation:
            return .awaitingCalculation
        }
    }

    private static func description(for reason: TangemPayTransactionCashback.ExclusionReason) -> String {
        switch reason {
        case .merchantCountry: Localization.tangemPayTransactionDetailsCashbackRegionExcluded
        case .mcc: Localization.tangemPayTransactionDetailsCashbackMccExcluded
        case .monthlyCap: Localization.tangemPayTransactionDetailsCashbackCapReached
        case .belowMin: Localization.tangemPayTransactionDetailsCashbackBelowMin
        }
    }

    private func status(
        for status: TangemPaySpendDisplayInput.Status,
        declinedReason: String?
    ) -> TangemPayTransactionStatusView.Model {
        switch status {
        case .pending:
            .init(style: .inProgress, title: Localization.tangemPayStatusPending, reason: nil)
        case .completed:
            .init(style: .completed, title: Localization.tangemPayStatusCompleted, reason: nil)
        case .declined:
            .init(
                style: .rejected,
                title: Localization.tangemPayStatusDeclined,
                reason: TangemPayTransactionDeclineReasonMapper.declinedText(for: declinedReason)
            )
        case .reversed:
            .init(style: .reversed, title: Localization.tangemPayStatusReversed, reason: nil)
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let day = dateFormatter.string(from: date)
        let time = date.formatted(date: .omitted, time: .shortened)
        return "\(day), \(time)"
    }
}

// MARK: - History projection

extension TangemPayTransactionRecord {
    func redesignedDisplayModel(
        using mapper: TangemPayTransactionDetailsRedesignedMapper
    ) -> TangemPayTransactionDetailsDisplayModel {
        switch record.displayRecord {
        case .merchant(let merchant): mapper.map(spend: merchant.displayInput)
        case .collateral(let collateral): mapper.map(collateral: collateral.displayInput)
        case .payment(let payment): mapper.map(payment: payment.displayInput)
        case .fee(let fee): mapper.map(fee: fee.displayInput)
        }
    }
}

// MARK: - Push projection

extension TangemPayPushPayload {
    func redesignedDisplayModel(
        using mapper: TangemPayTransactionDetailsRedesignedMapper
    ) -> TangemPayTransactionDetailsDisplayModel? {
        switch body {
        case .transactionSpend(let spend),
             .transactionSpendRefund(let spend),
             .declinedTopUp(let spend),
             .declinedReason1(let spend),
             .declinedReason2(let spend),
             .declinedReason3(let spend),
             .declinedReason4(let spend),
             .declinedReason5(let spend),
             .declinedReason6(let spend),
             .declinedReason7(let spend),
             .declinedReason8(let spend),
             .declinedReason9(let spend),
             .declinedReason10(let spend),
             .declinedReason11(let spend),
             .declinedReason12(let spend),
             .declinedReason13(let spend),
             .declinedReason14(let spend),
             .declinedReason15(let spend),
             .declinedReason16(let spend),
             .declinedReason17(let spend):
            mapper.map(spend: spend.displayInput)
        case .collateralWithdraw(let collateral):
            mapper.map(collateral: collateral.displayInput(isOutgoing: true))
        case .collateralDeposit(let collateral):
            mapper.map(collateral: collateral.displayInput(isOutgoing: false))
        case .cardReady, .thresholdTopUp:
            nil
        }
    }
}
