//
//  TangemPayPushParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Reads a payment push out of the dictionary a notification arrives in.
struct TangemPayPushParser {
    func parse(from userInfo: [AnyHashable: Any]) -> TangemPayPushPayload? {
        let extractor = Extractor<TangemPayPushPayload.CodingKeys>(userInfo: userInfo)

        guard let typeString = extractor.string(.type),
              let rawType = TangemPayPushPayload.RawType(rawValue: typeString),
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

    private func parseBody(rawType: TangemPayPushPayload.RawType, userInfo: [AnyHashable: Any]) -> TangemPayPushPayload.Body? {
        switch rawType {
        case .cardReady:
            return .cardReady
        case .transactionSpend:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.transactionSpend)
        case .transactionSpendRefund:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.transactionSpendRefund)
        case .declinedTopUp:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedTopUp)
        case .declinedReason1:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason1)
        case .declinedReason2:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason2)
        case .declinedReason3:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason3)
        case .declinedReason4:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason4)
        case .declinedReason5:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason5)
        case .declinedReason6:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason6)
        case .declinedReason7:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason7)
        case .declinedReason8:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason8)
        case .declinedReason9:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason9)
        case .declinedReason10:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason10)
        case .declinedReason11:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason11)
        case .declinedReason12:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason12)
        case .declinedReason13:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason13)
        case .declinedReason14:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason14)
        case .declinedReason15:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason15)
        case .declinedReason16:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason16)
        case .declinedReason17:
            return parseSpend(userInfo: userInfo).map(TangemPayPushPayload.Body.declinedReason17)
        case .collateralWithdraw:
            return parseCollateral(userInfo: userInfo).map(TangemPayPushPayload.Body.collateralWithdraw)
        case .collateralDeposit:
            return parseCollateral(userInfo: userInfo).map(TangemPayPushPayload.Body.collateralDeposit)
        case .cashbackTopUp:
            return parseCollateral(userInfo: userInfo).map(TangemPayPushPayload.Body.cashbackTopUp)
        case .thresholdTopUp:
            return .thresholdTopUp
        }
    }

    private func parseSpend(userInfo: [AnyHashable: Any]) -> TangemPayPushPayload.Spend? {
        let extractor = Extractor<TangemPayPushPayload.Spend.CodingKeys>(userInfo: userInfo)

        guard let transactionId = extractor.string(.transactionId),
              let amount = extractor.decimal(.amount),
              let currency = extractor.string(.currency),
              let authorizedAt = extractor.date(.authorizedAt),
              let statusString = extractor.string(.status),
              let status = TangemPayPushPayload.Spend.Status(rawValue: statusString)
        else {
            return nil
        }

        return TangemPayPushPayload.Spend(
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

    private func parseCollateral(userInfo: [AnyHashable: Any]) -> TangemPayPushPayload.Collateral? {
        let extractor = Extractor<TangemPayPushPayload.Collateral.CodingKeys>(userInfo: userInfo)

        guard let transactionId = extractor.string(.transactionId),
              let amount = extractor.decimal(.amount),
              let currency = extractor.string(.currency),
              let postedAt = extractor.date(.postedAt)
        else {
            return nil
        }

        return TangemPayPushPayload.Collateral(
            transactionId: transactionId,
            amount: amount,
            currency: currency,
            postedAt: postedAt,
            balance: extractor.decimal(.balance),
            transactionHash: extractor.string(.transactionHash)
        )
    }
}

private let pushPayloadDateFormatters: [DateFormatter] = {
    let formats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss",
    ]

    return formats.map { format in
        let formatter = DateFormatter(dateFormat: format)
        formatter.locale = .posixEnUS
        return formatter
    }
}()

private extension TangemPayPushParser {
    struct Extractor<Keys: CodingKey> {
        let userInfo: [AnyHashable: Any]

        func string(_ key: Keys) -> String? {
            (userInfo[key.stringValue] as? String)?.nilIfEmpty
        }

        func decimal(_ key: Keys) -> Decimal? {
            string(key).flatMap { Decimal(string: $0) }
        }

        func date(_ key: Keys) -> Date? {
            guard let string = string(key) else {
                return nil
            }

            return pushPayloadDateFormatters
                .lazy
                .compactMap { $0.date(from: string) }
                .first
        }

        func url(_ key: Keys) -> URL? {
            string(key).flatMap(URL.init(string:))
        }
    }
}
