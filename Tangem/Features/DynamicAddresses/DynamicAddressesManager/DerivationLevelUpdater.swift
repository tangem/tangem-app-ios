//
//  DerivationLevelUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol DerivationLevelUpdater {
    func update(blockchainNetwork: BlockchainNetwork, for tokenItem: TokenItem)
}
