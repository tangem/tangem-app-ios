//
//  CommonP2PDelegatorAddressProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

struct CommonP2PDelegatorAddressProvider: P2PDelegatorAddressProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func delegatorAddresses() -> [String] {
        AccountWalletModelsAggregator
            .walletModels(from: userWalletRepository.models)
            .filter { walletModel in
                guard walletModel.tokenItem.isBlockchain else { return false }
                if case .ethereum = walletModel.tokenItem.blockchain {
                    return true
                }
                return false
            }
            .map(\.defaultAddressString)
    }
}
