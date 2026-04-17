//
//  CustomBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MockBlockBookConfig: BlockBookConfig {
    let urlNode: URL

    let apiKeyHeaderName: String? = nil
    let apiKeyHeaderValue: String? = nil

    init(urlNode: URL) {
        self.urlNode = urlNode
    }
}

extension MockBlockBookConfig {
    var host: String {
        urlNode.host ?? ""
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        BlockBookNode(rpcNode: urlNode, restNode: urlNode)
    }

    func path(for request: BlockBookTarget.Request) -> String {
        ""
    }
}
