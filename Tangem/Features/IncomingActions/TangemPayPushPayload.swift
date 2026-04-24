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
        case declinedTopUp(Spend)
        case collateralWithdraw(Collateral)
        case collateralDeposit(Collateral)
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

        fileprivate enum CodingKeys: String, CodingKey {
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

        fileprivate enum CodingKeys: String, CodingKey {
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

private extension TangemPayPushPayload {
    enum RawType: String {
        case cardReady = "card_ready"
        case transactionSpend = "transaction_spend"
        case collateralWithdraw = "collateral_withdraw"
        case collateralDeposit = "collateral_deposit"
        case declinedTopUp = "declined_top_up"
    }

    var rawType: RawType {
        switch body {
        case .cardReady: .cardReady
        case .transactionSpend: .transactionSpend
        case .collateralWithdraw: .collateralWithdraw
        case .collateralDeposit: .collateralDeposit
        case .declinedTopUp: .declinedTopUp
        }
    }
}

// MARK: - Encodable

public extension TangemPayPushPayload {
    private enum CodingKeys: String, CodingKey {
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
        case .cardReady:
            break
        case .transactionSpend(let spend), .declinedTopUp(let spend):
            try spend.encode(to: encoder)
        case .collateralWithdraw(let collateral), .collateralDeposit(let collateral):
            try collateral.encode(to: encoder)
        }
    }
}

// MARK: - Parsing

extension TangemPayPushPayload {
    static func parse(from userInfo: [AnyHashable: Any]) -> TangemPayPushPayload? {
        let extractor = Extractor<CodingKeys>(userInfo: userInfo)

        guard let typeString = extractor.string(.type),
              let rawType = RawType(rawValue: typeString),
              let customerWalletId = extractor.string(.customerWalletId),
              let customerId = extractor.string(.customerId),
              let body = parseBody(rawType: rawType, userInfo: userInfo)
        else {
            return nil
        }

        return TangemPayPushPayload(
            customerWalletId: customerWalletId,
            customerId: customerId,
            body: body
        )
    }

    private static func parseBody(rawType: RawType, userInfo: [AnyHashable: Any]) -> Body? {
        switch rawType {
        case .cardReady:
            return .cardReady
        case .transactionSpend:
            return parseSpend(userInfo: userInfo).map(Body.transactionSpend)
        case .declinedTopUp:
            return parseSpend(userInfo: userInfo).map(Body.declinedTopUp)
        case .collateralWithdraw:
            return parseCollateral(userInfo: userInfo).map(Body.collateralWithdraw)
        case .collateralDeposit:
            return parseCollateral(userInfo: userInfo).map(Body.collateralDeposit)
        }
    }

    private static func parseSpend(userInfo: [AnyHashable: Any]) -> Spend? {
        let extractor = Extractor<Spend.CodingKeys>(userInfo: userInfo)

        guard let transactionId = extractor.string(.transactionId),
              let amount = extractor.decimal(.amount),
              let currency = extractor.string(.currency),
              let authorizedAt = extractor.date(.authorizedAt),
              let statusString = extractor.string(.status),
              let status = Spend.Status(rawValue: statusString)
        else {
            return nil
        }

        return Spend(
            transactionId: transactionId,
            amount: amount,
            currency: currency,
            authorizedAt: authorizedAt,
            status: status,
            declinedReason: extractor.string(.declinedReason),
            last4: extractor.string(.last4),
            balance: extractor.decimal(.balance),
            merchantName: extractor.string(.merchantName),
            enrichedMerchantName: extractor.string(.enrichedMerchantName),
            merchantCategory: extractor.string(.merchantCategory),
            merchantCategoryCode: extractor.string(.merchantCategoryCode),
            localAmount: extractor.decimal(.localAmount),
            localCurrency: extractor.string(.localCurrency),
            enrichedMerchantIcon: extractor.url(.enrichedMerchantIcon),
            enrichedMerchantCategory: extractor.string(.enrichedMerchantCategory)
        )
    }

    private static func parseCollateral(userInfo: [AnyHashable: Any]) -> Collateral? {
        let extractor = Extractor<Collateral.CodingKeys>(userInfo: userInfo)

        guard let transactionId = extractor.string(.transactionId),
              let amount = extractor.decimal(.amount),
              let currency = extractor.string(.currency),
              let postedAt = extractor.date(.postedAt)
        else {
            return nil
        }

        return Collateral(
            transactionId: transactionId,
            amount: amount,
            currency: currency,
            postedAt: postedAt,
            balance: extractor.decimal(.balance),
            transactionHash: extractor.string(.transactionHash)
        )
    }
}

// MARK: - Extractor

private let pushPayloadDateFormatter = ISO8601DateFormatter()

private extension TangemPayPushPayload {
    struct Extractor<Keys: CodingKey> {
        let userInfo: [AnyHashable: Any]

        func string(_ key: Keys) -> String? {
            (userInfo[key.stringValue] as? String)?.nilIfEmpty
        }

        func decimal(_ key: Keys) -> Decimal? {
            string(key).flatMap { Decimal(string: $0) }
        }

        func date(_ key: Keys) -> Date? {
            string(key).flatMap(pushPayloadDateFormatter.date(from:))
        }

        func url(_ key: Keys) -> URL? {
            string(key).flatMap(URL.init(string:))
        }
    }
}
