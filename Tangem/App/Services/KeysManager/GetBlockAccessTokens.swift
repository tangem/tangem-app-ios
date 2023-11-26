//
//  GetBlockAccessTokens.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct GetBlockAccessToken: Decodable {
    let blockBookRest: String?
    let jsonRpc: String?
    let rest: String?
    let rosetta: String?
}

extension BlockchainSdkConfig.GetBlockCredentials {
    init(_ json: [String: GetBlockAccessToken]) {
        var credentials: [BlockchainSdkConfig.GetBlockCredentials.Credential] = []

        json.forEach { key, values in
            guard let blockchain = Blockchain.allMainnetCases.first(where: { $0.codingKey == key }) else {
                return
            }

            if let key = values.blockBookRest {
                credentials.append(.init(blockchain: blockchain, type: .blockBook, key: key))
            }

            if let key = values.jsonRpc {
                credentials.append(.init(blockchain: blockchain, type: .jsonRpc, key: key))
            }

            if let key = values.rosetta {
                credentials.append(.init(blockchain: blockchain, type: .rosseta, key: key))
            }

            if let key = values.rest {
                credentials.append(.init(blockchain: blockchain, type: .rest, key: key))
            }
        }

        self.init(credentials: credentials)
    }
}
