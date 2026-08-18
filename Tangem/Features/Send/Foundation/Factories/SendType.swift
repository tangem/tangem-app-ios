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

/// Mirrors the two `SwapFlowFactory` inits: the source side is fixed, or the receive side is.
/// `configuration` locks the pair and overrides the title for account funding flows.
enum PredefinedSwapParameters {
    case from(
        _ source: SendSwapableToken,
        pair: PairResolution = .userSelection,
        extras: Extras? = nil,
        configuration: SwapFlowConfiguration = .default
    )
    case to(
        _ receive: SendSwapableToken,
        sourceResolver: (any SwapSourceTokenResolver)? = nil,
        configuration: SwapFlowConfiguration = .default
    )

    /// How a pair with a fixed source gets settled. A known destination leaves the resolver nothing
    /// to do, so the two can't be passed together.
    enum PairResolution {
        case fixed(receive: SendReceiveToken)
        /// The source is a guess until balances settle; the resolver replaces it then.
        case deferred(sourceResolver: any SwapSourceTokenResolver)
        case userSelection
    }

    /// Optional preselections carried by a `tangem://swap` deeplink on top of the resolved pair: an initial
    /// FROM amount to prefill and a provider to auto-select once the pair's providers arrive.
    struct Extras {
        let sourceAmount: Decimal?
        let providerId: ExpressProvider.Id?

        init(sourceAmount: Decimal? = nil, providerId: ExpressProvider.Id? = nil) {
            self.sourceAmount = sourceAmount
            self.providerId = providerId
        }
    }
}

extension PredefinedSwapParameters.PairResolution {
    /// For call sites whose destination lookup can come up empty.
    static func fixed(receiveOrUserSelection token: SendReceiveToken?) -> Self {
        token.map { .fixed(receive: $0) } ?? .userSelection
    }

    var receiveToken: SendReceiveToken? {
        switch self {
        case .fixed(let token): token
        case .deferred, .userSelection: nil
        }
    }

    var sourceResolver: (any SwapSourceTokenResolver)? {
        switch self {
        case .deferred(let resolver): resolver
        case .fixed, .userSelection: nil
        }
    }
}

/// Swap direction for a token-details entry point. `automatic` defers to the balance-based pair
/// resolver; `from`/`to` force the current token as source/destination respectively.
enum SwapDirection {
    case automatic
    case from
    case to
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
