//
//  CommonBlockchainSettingsUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonBlockchainSettingsUpdater: BlockchainSettingsUpdater {
    let userTokensRepository: UserTokensRepository

    func update(settings: BlockchainSettings?, for tokenItem: TokenItem) -> BlockchainNetwork {
        let blockchainNetwork = tokenItem.blockchainNetwork.with(settings: settings)
        userTokensRepository.performBatchUpdates { updater in
            updater.updateBlockchainNetwork(blockchainNetwork, for: tokenItem)
        }
        return blockchainNetwork
    }
}
