//
//  CloreBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CloreBlockBookConfig: BlockBookConfig {
    let urlNode: URL

    let apiKeyHeaderName: String?
    let apiKeyHeaderValue: String?

    init(urlNode: URL, apiKeyHeaderName: String? = nil, apiKeyHeaderValue: String? = nil) {
        self.urlNode = urlNode
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiKeyHeaderValue = apiKeyHeaderValue
    }
}

extension CloreBlockBookConfig {
    var host: String {
        return urlNode.host ?? ""
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        guard blockchain == .clore else {
            assertionFailure("Blockchain does not supported for this blockbook")
            let emptyURL = URL(string: "")!
            return .init(rpcNode: emptyURL, restNode: emptyURL)
        }

        return BlockBookNode(rpcNode: urlNode, restNode: urlNode)
    }

    func path(for request: BlockBookTarget.Request) -> String {
        return "api/v2"
    }
}
