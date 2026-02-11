//
//  StakingFeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

class StakingFeatureProvider {
    private let isFeatureAvailable: Bool
    private let hardwareLimitationsUtil: HardwareLimitationsUtil

    init(config: UserWalletConfig) {
        hardwareLimitationsUtil = HardwareLimitationsUtil(config: config)
        isFeatureAvailable = config.isFeatureVisible(.staking)
    }

    func yieldId(for tokenItem: TokenItem) -> String? {
        guard isFeatureAvailable else {
            return nil
        }

        guard hardwareLimitationsUtil.canPerformContractInteractions(with: tokenItem) else {
            return nil
        }

        // cardano staking require extended key
        if case .cardano(let extended) = tokenItem.blockchain, !extended {
            return nil
        }

        guard let stakingTokenItem = tokenItem.stakingTokenItem else {
            return nil
        }

        let item = StakingItem(network: stakingTokenItem.network, contractAddress: stakingTokenItem.contractAddress)
        let itemID = item.id
        let isSupported = StakingFeatureProvider.supportedBlockchainItems.contains(item)
        let isTesting = FeatureStorage.instance.stakingBlockchainsIds.contains(itemID)

        guard isSupported || isTesting else {
            return nil
        }

        guard let yieldId = yieldIds(item: item) else {
            return nil
        }

        return yieldId
    }

    func isAvailable(for tokenItem: TokenItem) -> Bool {
        yieldId(for: tokenItem) != nil
    }
}

extension StakingFeatureProvider {
    static var supportedBlockchainItems: Set<StakingItem> {
        [
            StakingItem(network: .solana, contractAddress: nil),
            StakingItem(network: .cosmos, contractAddress: nil),
            StakingItem(network: .tron, contractAddress: nil),
            StakingItem(
                network: .ethereum,
                contractAddress: StakingConstants.polygonContractAddress
            ),
            StakingItem(network: .bsc, contractAddress: nil),
            StakingItem(network: .ton, contractAddress: nil),
            StakingItem(network: .cardano, contractAddress: nil),
        ]
    }

    static var testableBlockchainItems: Set<StakingItem> {
        [
            StakingItem(network: .ethereum, contractAddress: nil),
        ]
    }

    func yieldIds(item: StakingItem) -> String? {
        switch (item.network, item.contractAddress) {
        case (.solana, .none):
            return StakingIntegrationId.solana.rawValue
        case (.cosmos, .none):
            return StakingIntegrationId.cosmos.rawValue
        case (.ethereum, StakingConstants.polygonContractAddress):
            return StakingIntegrationId.matic.rawValue
        case (.tron, .none):
            return StakingIntegrationId.tron.rawValue
        case (.bsc, .none):
            return StakingIntegrationId.bsc.rawValue
        case (.ton, .none):
            return StakingIntegrationId.ton.rawValue
        case (.cardano, .none):
            return StakingIntegrationId.cardano.rawValue
        case (.ethereum, .none):
            return StakingIntegrationId.ethereumP2P.rawValue // dummy id for consistency
        default:
            return nil
        }
    }
}

extension StakingFeatureProvider {
    struct StakingItem: Hashable {
        let network: StakingNetworkType
        let contractAddress: String?

        var id: String {
            var id = network.rawValue
            if let contractAddress {
                id += "_\(contractAddress)"
            }
            return id
        }

        var name: String {
            "\(network.rawValue.capitalizingFirstLetter())\(contractAddress.map { "\nToken: (\($0))" } ?? "")"
        }
    }
}
