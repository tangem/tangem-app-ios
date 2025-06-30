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
    let derivationPath: String?
    let userWalletId: String?

    func buildURL(scheme: IncomingActionScheme) -> URL {
        var components = URLComponents()
        components.scheme = scheme.baseScheme.replacingOccurrences(of: "://", with: "")
        components.host = IncomingActionConstants.DeeplinkDestination.token.rawValue
        components.queryItems = [
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.networkId, value: networkId),
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.tokenId, value: tokenId),
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.walletId, value: walletId),
            URLQueryItem(name: IncomingActionConstants.DeeplinkParams.type, value: type),
        ]

        [
            derivationPath.map { URLQueryItem(name: IncomingActionConstants.DeeplinkParams.derivationPath, value: $0) },
            userWalletId.map { URLQueryItem(name: IncomingActionConstants.DeeplinkParams.userWalletId, value: $0) },
        ]
        .compactMap { $0 }
        .forEach { components.queryItems?.append($0) }

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
