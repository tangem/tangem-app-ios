//
//  TokenEnricher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenEnricher {
    func enrichToken(blockchainNetwork: BlockchainNetwork, contractAddress: String) async throws -> TokenItem
}
