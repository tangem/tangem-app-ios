//
//  TransactionPushActionURLHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TransactionPushActionURLHelper: IncomingActionURLHelper {
    let type: String
    let networkId: String
    let tokenId: String
    let walletId: String

    func buildURL(scheme: IncomingActionScheme) -> URL {
        var components = URLComponents()
        components.scheme = scheme.baseScheme.replacingOccurrences(of: "://", with: "")
        components.host = Constants.tokenHost
        components.queryItems = [
            URLQueryItem(name: Constants.networkIdKey, value: networkId),
            URLQueryItem(name: Constants.tokenIdKey, value: tokenId),
            URLQueryItem(name: Constants.walletIdKey, value: walletId),
            URLQueryItem(name: Constants.typeKey, value: type),
        ]

        guard let url = components.url else {
            assertionFailure("Failed to build URL with given components.")
            return URL(string: IncomingActionConstants.universalLinkScheme)!
        }

        return url
    }

    func parse(_ url: URL) throws -> IncomingAction? {
        assertionFailure("parse(_:) not implemented")
        return nil
    }
}

extension TransactionPushActionURLHelper {
    enum Constants {
        static let typeKey = "type"
        static let networkIdKey = "network_id"
        static let tokenIdKey = "token_id"
        static let walletIdKey = "wallet_id"
        static let tokenHost = "token"
        static let incomeTransaction = "income_transaction"
    }
}
