//
//  LendingOnAave.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum LendingOnAave {
    static let blockchain: Blockchain = .ethereum(testnet: false)
    static let wrappedNativeAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    static let nativeSupportVersion: YieldModuleVersion = .v3
    static let performanceFee = Decimal(15) / 100

    static func isOffered(on walletModel: any WalletModel) -> Bool {
        guard FeatureProvider.isAvailable(.lendingOnAave),
              case .blockchain(let network) = walletModel.tokenItem,
              network.blockchain == blockchain,
              !walletModel.isJointAccountParticipant else {
            return false
        }

        return walletModel.lendingModuleReader != nil
    }
}
