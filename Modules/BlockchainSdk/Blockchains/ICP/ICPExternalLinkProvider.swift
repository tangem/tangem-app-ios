//
//  ICPExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ICPExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return nil
    }

    private let baseExplorerURL = URL(string: "https://dashboard.internetcomputer.org")

    func url(address: String, contractAddress: String?) -> URL? {
        baseExplorerURL?.appendingPathComponent("tokens/account").appendingPathComponent(address)
    }

    func url(transaction blockIndex: String) -> URL? {
        baseExplorerURL?.appendingPathComponent("tokens/tx").appendingPathComponent(blockIndex)
    }
}
