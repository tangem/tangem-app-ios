//
//  CommonEarnEthereumP2PFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

final class CommonEarnEthereumP2PFilter: EarnEthereumP2PFilter {
    private let stakingYieldInfoProvider: StakingYieldInfoProvider

    init(stakingYieldInfoProvider: StakingYieldInfoProvider) {
        self.stakingYieldInfoProvider = stakingYieldInfoProvider
    }

    convenience init() {
        self.init(stakingYieldInfoProvider: InjectedValues[\.stakingYieldInfoProvider])
    }

    func filter(_ items: [EarnDTO.List.Item]) async throws -> [EarnDTO.List.Item] {
        guard items.contains(where: Self.isEthereumP2PStakingItem) else {
            return items
        }

        let shouldHide: Bool
        do {
            let yield = try await stakingYieldInfoProvider.yieldInfo(for: StakingIntegrationId.ethereumP2P.rawValue)
            let maxLimit = yield.targets.compactMap(\.maximumStakeAmount).max() ?? .zero
            shouldHide = maxLimit <= Constants.minVisibleLimit
        } catch let error as CancellationError {
            throw error
        } catch {
            shouldHide = true
        }

        guard shouldHide else { return items }
        return items.filter { !Self.isEthereumP2PStakingItem($0) }
    }

    static func isEthereumP2PStakingItem(_ item: EarnDTO.List.Item) -> Bool {
        item.networkId.lowercased() == Constants.ethereumNetworkId
            && item.token.symbol.uppercased() == Constants.ethSymbol
            && item.type.lowercased() == Constants.stakingType
            && (item.token.address?.isEmpty ?? true)
    }
}

private extension CommonEarnEthereumP2PFilter {
    enum Constants {
        static let minVisibleLimit: Decimal = 0.1
        static let ethereumNetworkId = "ethereum"
        static let ethSymbol = "ETH"
        static let stakingType = "staking"
    }
}
