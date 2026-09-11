//
//  TangemPayMerchantRecord.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

struct TangemPayMerchantRecord {
    let transactionDate: Date
    let amount: Decimal
    let authorizedAmount: Decimal
    let currency: String
    let localAmount: Decimal?
    let localCurrency: String?
    let merchantName: String?
    let enrichedMerchantName: String?
    let enrichedMerchantIcon: URL?
    let merchantCategory: String?
    let enrichedMerchantCategory: String?
    let merchantCategoryCode: String?
    let cardId: String
    let cardDisplayName: String?
    let cardNumberEnd: String?
    let status: TangemPayTransactionHistoryResponse.PaymentStatus
    let declinedReason: String?
    let cashback: Decimal?
    let cashbackStatus: TangemPayCashbackStatus?
    let cashbackCurrencyCode: String?

    var isDeclined: Bool {
        status == .declined
    }
}

enum TangemPayDisplayRecord {
    case merchant(TangemPayMerchantRecord)
    case collateral(TangemPayTransactionHistoryResponse.Collateral)
    case payment(TangemPayTransactionHistoryResponse.Payment)
    case fee(TangemPayTransactionHistoryResponse.Fee)
}

// MARK: - Projections

extension TangemPayTransactionHistoryResponse.Record {
    var displayRecord: TangemPayDisplayRecord {
        switch self {
        case .spend(let spend): .merchant(spend.merchantRecord)
        case .refund(let refund): .merchant(refund.merchantRecord)
        case .collateral(let collateral): .collateral(collateral)
        case .payment(let payment): .payment(payment)
        case .fee(let fee): .fee(fee)
        }
    }
}

extension TangemPayTransactionHistoryResponse.Spend {
    var transactionDate: Date {
        amount < 0 ? (postedAt ?? authorizedAt) : authorizedAt
    }

    var merchantRecord: TangemPayMerchantRecord {
        TangemPayMerchantRecord(
            transactionDate: transactionDate,
            amount: amount,
            authorizedAmount: authorizedAmount ?? amount,
            currency: currency,
            localAmount: localAmount,
            localCurrency: localCurrency,
            merchantName: merchantName,
            enrichedMerchantName: enrichedMerchantName,
            enrichedMerchantIcon: enrichedMerchantIcon,
            merchantCategory: merchantCategory,
            enrichedMerchantCategory: enrichedMerchantCategory,
            merchantCategoryCode: merchantCategoryCode,
            cardId: cardId,
            cardDisplayName: cardDisplayName,
            cardNumberEnd: cardNumberEnd,
            status: status,
            declinedReason: declinedReason,
            cashback: cashback,
            cashbackStatus: cashbackStatus,
            cashbackCurrencyCode: cashbackCurrencyCode
        )
    }
}

extension TangemPayTransactionHistoryResponse.Refund {
    var transactionDate: Date {
        postedAt ?? authorizedAt
    }

    var merchantRecord: TangemPayMerchantRecord {
        TangemPayMerchantRecord(
            transactionDate: transactionDate,
            amount: amount,
            authorizedAmount: amount,
            currency: currency,
            localAmount: localAmount,
            localCurrency: localCurrency,
            merchantName: merchantName,
            enrichedMerchantName: enrichedMerchantName,
            enrichedMerchantIcon: enrichedMerchantIcon,
            merchantCategory: merchantCategory,
            enrichedMerchantCategory: enrichedMerchantCategory,
            merchantCategoryCode: merchantCategoryCode,
            cardId: cardId,
            cardDisplayName: cardDisplayName,
            cardNumberEnd: cardNumberEnd,
            status: status,
            declinedReason: nil,
            cashback: cashback,
            cashbackStatus: cashbackStatus,
            cashbackCurrencyCode: cashbackCurrencyCode
        )
    }
}
