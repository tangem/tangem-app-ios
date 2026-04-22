//
//  DerivationModeUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol DerivationModeUpdater {
    @discardableResult
    func update(derivationMode: BlockchainNetwork.DerivationMode, for tokenItem: TokenItem) -> BlockchainNetwork
}
