//
//  BlockchainSettingsUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol BlockchainSettingsUpdater {
    @discardableResult
    func update(settings: BlockchainSettings?, for tokenItem: TokenItem) -> BlockchainNetwork
}
