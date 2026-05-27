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
    case send(SendWithSwapToken, parameters: PredefinedSendParameters? = nil)
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

struct PredefinedSendParameters {
    let destination: String
    let amount: Decimal?
    let tag: String?
    let initialStep: InitialStep

    init(
        destination: String,
        amount: Decimal? = nil,
        tag: String? = nil,
        initialStep: InitialStep = .amount
    ) {
        self.destination = destination
        self.amount = amount
        self.tag = tag
        self.initialStep = initialStep
    }
}

extension PredefinedSendParameters {
    enum InitialStep {
        case amount
        case amountThenSummary
        case summary
    }
}

enum PredefinedSwapParameters {
    case pair(source: SendSwapableToken, receive: SendSwapableToken? = nil)
    case from(_ source: SendSwapableToken, receive: SendReceiveToken? = nil)
    case to(_ receive: SendSwapableToken)
    case deferredPairResolution(source: SendSwapableToken, resolver: MainSwapPairResolver)
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
