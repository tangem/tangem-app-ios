//
//  BlockBookConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol BlockBookConfig {
    var apiKeyHeaderName: String? { get }
    var apiKeyHeaderValue: String? { get }

    var host: String { get }

    func node(for blockchain: Blockchain) -> BlockBookNode
    func path(for request: BlockBookTarget.Request) -> String
}
