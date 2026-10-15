//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
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
        walletModelDependenciesProvider: WalletModelDependenciesProvider
    )
    case unstaking(SendStakingableToken, manager: StakingManager, action: StakingAction)
    case restaking(SendStakingableToken, manager: StakingManager, action: StakingAction)
    case stakingSingleAction(SendStakingableToken, manager: StakingManager, action: StakingAction)
    case onramp(SendSourceToken, parameters: PredefinedOnrampParameters = .none)
}

// MARK: - PredefinedSendParameters

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

// MARK: - PredefinedSwapParameters

/// The swap flow opens either from a known source token or into a known receive token.
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

extension PredefinedSwapParameters {
    /// The wallet the swap opens for.
    var userWalletId: UserWalletId {
        userWalletInfo.id
    }

    var userWalletInfo: UserWalletInfo {
        switch self {
        case .from(let source, _, _, _): source.userWalletInfo
        case .to(let receive, _, _): receive.userWalletInfo
        }
    }

    var sourceToken: SendSwapableToken? {
        switch self {
        case .from(let source, _, _, _): source
        case .to: nil
        }
    }

    var receiveToken: SendReceiveToken? {
        switch self {
        case .from(_, let pair, _, _): pair.receiveToken
        case .to(let receive, _, _): receive
        }
    }

    var extras: Extras? {
        switch self {
        case .from(_, _, let extras, _): extras
        case .to: nil
        }
    }

    var configuration: SwapFlowConfiguration {
        switch self {
        case .from(_, _, _, let configuration): configuration
        case .to(_, _, let configuration): configuration
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

/// Which side of the swap a token-details entry point puts the current token on: `from` makes it the
/// source, `to` the destination.
enum SwapDirection {
    case from
    case to

    static func build(for walletModel: any WalletModel) -> SwapDirection {
        walletModel.fiatAvailableBalance > 0 ? .from : .to
    }
}

// MARK: - PredefinedSellParameters

struct PredefinedSellParameters {
    let amount: Decimal
    let destination: String
    let tag: String?
}

// MARK: - PredefinedNFTParameters

struct PredefinedNFTParameters {
    let asset: NFTAsset
    let collection: NFTCollection
}

// MARK: - PredefinedOnrampParameters

struct PredefinedOnrampParameters: Hashable {
    static let none = PredefinedOnrampParameters(amount: .none, preferredValues: .none)

    let amount: Decimal?
    let preferredValues: PreferredValues

    init(amount: Decimal? = .none, preferredValues: PreferredValues = .none) {
        self.amount = amount
        self.preferredValues = preferredValues
    }
}
