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
    var isStakingAvailable: Bool {
        FeatureProvider.isAvailable(.staking)
    }

    func yieldId(for tokenItem: TokenItem) -> String? {
        guard isStakingAvailable else {
            return nil
        }

        guard AppUtils().canStake(for: tokenItem) else {
            return nil
        }

        guard let stakingTokenItem = tokenItem.stakingTokenItem else {
            return nil
        }

        let itemID = stakingTokenItem.id
        let isSupported = supportedBlockchainIds.contains(itemID)
        let isTesting = FeatureStorage().stakingBlockchainsIds.contains(itemID)

        guard isSupported || isTesting else {
            return nil
        }

        guard let yieldId = yieldIds(item: stakingTokenItem) else {
            return nil
        }

        return yieldId
    }

    func isAvailable(for tokenItem: TokenItem) -> Bool {
        yieldId(for: tokenItem) != nil
    }

    func canStake(with userWalletModel: UserWalletModel, by walletModel: WalletModel) -> Bool {
        [
            isAvailable(for: walletModel.tokenItem),
            userWalletModel.config.isFeatureVisible(.staking),
            yieldId(for: walletModel.tokenItem) != nil,
            !walletModel.isCustom,
        ].allConforms { $0 }
    }
}

extension StakingFeatureProvider {
    var supportedBlockchainIds: Set<String> {
        [
        ]
    }

    var testableBlockchainIds: Set<StakingTokenItem> {
        [
            StakingTokenItem(network: .solana, contractAddress: nil),
            StakingTokenItem(network: .cosmos, contractAddress: nil),
            StakingTokenItem(network: .ethereum, contractAddress: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0"),
        ]
    }

    func yieldIds(item: StakingTokenItem) -> String? {
        switch (item.network, item.contractAddress) {
        case (.solana, .none):
            return "solana-sol-native-multivalidator-staking"
        case (.cosmos, .none):
            return "cosmos-atom-native-staking"
        case (.ethereum, "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0"):
            return "ethereum-matic-native-staking"
        default:
            return nil
        }
    }
}

public extension StakingTokenItem {
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
