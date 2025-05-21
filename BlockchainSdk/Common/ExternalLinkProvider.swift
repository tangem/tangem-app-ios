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
}
