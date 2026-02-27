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
    case send(SendWithSwapToken)
    case sell(SendTransferableToken, parameters: PredefinedSellParameters)
    case nft(SendTransferableToken, parameters: PredefinedNFTParameters)
    case swap(PredefinedSwapParameters)
    case staking(
        SendStakingableToken,
        manager: StakingManager,
        walletModelDependenciesProvider: WalletModelDependenciesProvider,
        blockchainParams: StakingBlockchainParams
    )
    case unstaking(SendStakingableToken, manager: StakingManager, action: UnstakingModel.Action)
    case restaking(SendStakingableToken, manager: StakingManager, action: RestakingModel.Action)
    case stakingSingleAction(SendStakingableToken, manager: StakingManager, action: StakingSingleActionModel.Action)
    case onramp(SendSourceToken, parameters: PredefinedOnrampParameters = .none)
}

// MARK: - Parameters

enum PredefinedSwapParameters {
    case from(_ source: SendSwapableToken, receive: SendReceiveToken? = nil)
    case to(_ receive: SendSwapableToken)
}

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
