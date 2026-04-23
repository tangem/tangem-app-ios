//
//  BlockchainExplorerProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExternalLinkProvider {
    var testnetFaucetURL: URL? { get }

    func url(address: String, contractAddress: String?) -> URL?
    func url(transaction hash: String) -> URL?
    /// Returns explorer URL for token transaction.
    /// - Default implementation: returns same value as url(transaction: hash).
    func tokenUrl(transaction hash: String) -> URL?
}

public extension ExternalLinkProvider {
    func tokenUrl(transaction hash: String) -> URL? {
        url(transaction: hash)
    }
}
