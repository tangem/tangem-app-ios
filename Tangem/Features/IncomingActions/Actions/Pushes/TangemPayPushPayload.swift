//
//  TangemPayPushPayload.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct TangemPayPushPayload: Equatable, Encodable {
    public let customerWalletId: String
    public let customerId: String
    public let body: Body
}

// MARK: - Body

public extension TangemPayPushPayload {
    enum Body: Equatable {
        case cardReady
        case transactionSpend(Spend)
        case transactionSpendRefund(Spend)
        case declinedTopUp(Spend)
        case declinedReason1(Spend)
        case declinedReason2(Spend)
        case declinedReason3(Spend)
        case declinedReason4(Spend)
        case declinedReason5(Spend)
        case declinedReason6(Spend)
        case declinedReason7(Spend)
        case declinedReason8(Spend)
        case declinedReason9(Spend)
        case declinedReason10(Spend)
        case declinedReason11(Spend)
        case declinedReason12(Spend)
        case declinedReason13(Spend)
        case declinedReason14(Spend)
        case declinedReason15(Spend)
        case declinedReason16(Spend)
        case declinedReason17(Spend)
        case collateralWithdraw(Collateral)
        case collateralDeposit(Collateral)
        case thresholdTopUp
    }

    struct Spend: Equatable, Encodable {
        let transactionId: String
        let amount: Decimal
        let currency: String
        let authorizedAt: Date
        let status: Status
        let declinedReason: String?
        let last4: String?
        let balance: Decimal?
        let merchantName: String?
        let enrichedMerchantName: String?
        let merchantCategory: String?
        let merchantCategoryCode: String?
        let localAmount: Decimal?
        let localCurrency: String?
        let enrichedMerchantIcon: URL?
        let enrichedMerchantCategory: String?

        enum Status: String, Equatable, Encodable {
            case approved
            case completed
            case declined
            case pending
            case reversed
        }

        enum CodingKeys: String, CodingKey {
            case transactionId = "transaction_id"
            case amount
            case currency
            case authorizedAt = "authorized_at"
            case status
            case declinedReason = "declined_reason"
            case last4
            case balance
            case merchantName = "merchant_name"
            case enrichedMerchantName = "enriched_merchant_name"
            case merchantCategory = "merchant_category"
            case merchantCategoryCode = "merchant_category_code"
            case localAmount = "local_amount"
            case localCurrency = "local_currency"
            case enrichedMerchantIcon = "enriched_merchant_icon"
            case enrichedMerchantCategory = "enriched_merchant_category"
        }
    }

    struct Collateral: Equatable, Encodable {
        let transactionId: String
        let amount: Decimal
        let currency: String
        let postedAt: Date
        let balance: Decimal?
        let transactionHash: String?

        enum CodingKeys: String, CodingKey {
            case transactionId = "transaction_id"
            case amount
            case currency
            case postedAt = "posted_at"
            case balance
            case transactionHash = "transaction_hash"
        }
    }
}

// MARK: - RawType

extension TangemPayPushPayload {
    enum RawType: String {
        case cardReady = "card_ready"
        case transactionSpend = "transaction_spend"
        case transactionSpendRefund = "transaction_spend_refund"
        case declinedTopUp = "declined_top_up"
        case declinedReason1 = "declined_reason1"
        case declinedReason2 = "declined_reason2"
        case declinedReason3 = "declined_reason3"
        case declinedReason4 = "declined_reason4"
        case declinedReason5 = "declined_reason5"
        case declinedReason6 = "declined_reason6"
        case declinedReason7 = "declined_reason7"
        case declinedReason8 = "declined_reason8"
        case declinedReason9 = "declined_reason9"
        case declinedReason10 = "declined_reason10"
        case declinedReason11 = "declined_reason11"
        case declinedReason12 = "declined_reason12"
        case declinedReason13 = "declined_reason13"
        case declinedReason14 = "declined_reason14"
        case declinedReason15 = "declined_reason15"
        case declinedReason16 = "declined_reason16"
        case declinedReason17 = "declined_reason17"
        case collateralWithdraw = "collateral_withdraw"
        case collateralDeposit = "collateral_deposit"
        case thresholdTopUp = "threshold1_top_up"
    }

    var rawType: RawType {
        switch body {
        case .cardReady: .cardReady
        case .transactionSpend: .transactionSpend
        case .transactionSpendRefund: .transactionSpendRefund
        case .declinedTopUp: .declinedTopUp
        case .declinedReason1: .declinedReason1
        case .declinedReason2: .declinedReason2
        case .declinedReason3: .declinedReason3
        case .declinedReason4: .declinedReason4
        case .declinedReason5: .declinedReason5
        case .declinedReason6: .declinedReason6
        case .declinedReason7: .declinedReason7
        case .declinedReason8: .declinedReason8
        case .declinedReason9: .declinedReason9
        case .declinedReason10: .declinedReason10
        case .declinedReason11: .declinedReason11
        case .declinedReason12: .declinedReason12
        case .declinedReason13: .declinedReason13
        case .declinedReason14: .declinedReason14
        case .declinedReason15: .declinedReason15
        case .declinedReason16: .declinedReason16
        case .declinedReason17: .declinedReason17
        case .collateralWithdraw: .collateralWithdraw
        case .collateralDeposit: .collateralDeposit
        case .thresholdTopUp: .thresholdTopUp
        }
    }
}

// MARK: - Encodable

public extension TangemPayPushPayload {
    enum CodingKeys: String, CodingKey {
        case customerWalletId = "customer_wallet_id"
        case customerId = "customer_id"
        case type
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(customerWalletId, forKey: .customerWalletId)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(rawType.rawValue, forKey: .type)

        switch body {
        case .cardReady, .thresholdTopUp:
            break
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
            try spend.encode(to: encoder)
        case .collateralWithdraw(let collateral), .collateralDeposit(let collateral):
            try collateral.encode(to: encoder)
        }
    }
}

// MARK: - Navigation

extension TangemPayPushPayload {
    /// Where the push leads. The card being ready and a top-up threshold open the payment account — the same
    /// screen a `tangem://pay-account` link opens, for the same wallet; a transaction has a sheet of its own.
    var action: DeeplinkNavigationAction {
        switch body {
        case .cardReady:
            .tangemPayAccount(TangemPayAccountDeeplink(screen: nil, userWalletId: customerWalletId))
        case .thresholdTopUp:
            .tangemPayAccount(TangemPayAccountDeeplink(screen: TangemPayOpeningAction.addFunds.rawValue, userWalletId: customerWalletId))
        default:
            .tangemPayTransaction(TangemPayTransactionDeeplink(payload: self))
        }
    }
}
