//
//  PublicBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PublicBlockBookConfig: BlockBookConfig {
    let urlNode: String

    let apiKeyHeaderName: String? = nil
    let apiKeyHeaderValue: String? = nil

    init(urlNode: String) {
        self.urlNode = urlNode
    }
}

extension PublicBlockBookConfig {
    var host: String {
        urlNode
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        return BlockBookNode(
            rpcNode: urlNode,
            restNode: ""
        )
    }

    func path(for request: BlockBookTarget.Request) -> String {
        ""
    }
}
