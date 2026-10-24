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
    let userWalletId: String
    let derivationPath: String?
    let transactionId: String?
    let accountId: String?

    func buildURL(scheme: IncomingActionScheme) -> URL {
        var components = URLComponents()
        components.scheme = scheme.baseScheme.replacingOccurrences(of: "://", with: "")
        components.host = TokenDeeplink.host
        components.queryItems = [
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.networkId, value: networkId),
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.tokenId, value: tokenId),
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.userWalletId, value: userWalletId),
            URLQueryItem(name: TokenDeeplink.Keys.type, value: type),
        ]

        if let derivationPath, derivationPath.isNotEmpty {
            components.queryItems?.append(URLQueryItem(name: IncomingActionConstants.DeeplinkParams.derivationPath, value: derivationPath))
        }

        if let transactionId, transactionId.isNotEmpty {
            components.queryItems?.append(URLQueryItem(name: TokenDeeplink.Keys.transactionId, value: transactionId))
        }

        if let accountId, accountId.isNotEmpty {
            components.queryItems?.append(URLQueryItem(name: IncomingActionConstants.DeeplinkParams.accountId, value: accountId))
        }

        guard let url = components.url else {
            assertionFailure("Failed to build URL with given components.")
            return URL(string: IncomingActionConstants.appScheme)!
        }

        return url
    }

    func parse(_ url: URL) throws -> IncomingAction? {
        assertionFailure("parse(_:) not implemented")
        return nil
    }
}
