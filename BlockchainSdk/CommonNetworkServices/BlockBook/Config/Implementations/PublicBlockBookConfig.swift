//
//  PublicBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PublicBlockBookConfig: BlockBookConfig {
    let urlNode: URL

    let apiKeyHeaderName: String? = nil
    let apiKeyHeaderValue: String? = nil

    init(urlNode: URL) {
        self.urlNode = urlNode
    }
}

extension PublicBlockBookConfig {
    var host: String {
        urlNode.absoluteString
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        BlockBookNode(rpcNode: urlNode, restNode: urlNode)
    }

    func path(for request: BlockBookTarget.Request) -> String {
        ""
    }
}
