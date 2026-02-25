//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import TangemStaking
import TangemExpress
import BlockchainSdk

enum SendType {
    case send(SendSourceToken, source: ExpressInteractorWalletModelWrapper)
    case swap(SendSourceToken)
    case sell(SendSourceToken, source: ExpressInteractorWalletModelWrapper, parameters: PredefinedSellParameters)
    case nft(SendSourceToken, source: ExpressInteractorWalletModelWrapper, parameters: PredefinedNFTParameters)
    case staking(SendSourceToken, manager: StakingManager, walletModelDependenciesProvider: WalletModelDependenciesProvider, blockchainParams: StakingBlockchainParams)
    case unstaking(SendSourceToken, manager: StakingManager, action: UnstakingModel.Action)
    case restaking(SendSourceToken, manager: StakingManager, action: RestakingModel.Action)
    case stakingSingleAction(SendSourceToken, manager: StakingManager, action: StakingSingleActionModel.Action)
    case onramp(SendSourceToken, parameters: PredefinedOnrampParameters = .none)
}

// MARK: - Parameters

struct PredefinedSellParameters {
    let amount: Decimal
    let destination: String
    let tag: String?
}

struct PredefinedNFTParameters {
    let asset: NFTAsset
    let collection: NFTCollection
}

struct PredefinedOnrampParameters: Hashable {
    static let none = PredefinedOnrampParameters(amount: .none, preferredValues: .none)

    let amount: Decimal?
    let preferredValues: PreferredValues

    init(amount: Decimal? = .none, preferredValues: PreferredValues = .none) {
        self.amount = amount
        self.preferredValues = preferredValues
    }
}
