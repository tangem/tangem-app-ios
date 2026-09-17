//
//  StakingDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

private typealias Shared = IncomingActionConstants.DeeplinkParams

/// `tangem://staking?token_id&network_id[&user_wallet_id&derivation_path]`
struct StakingDeeplink: HostNamedDeeplink, Equatable {
    static let host = "staking"

    let tokenId: String
    let networkId: String
    let userWalletId: String?
    let derivationPath: String?

    var action: DeeplinkNavigationAction { .staking(self) }

    init(tokenId: String, networkId: String, userWalletId: String? = nil, derivationPath: String? = nil) {
        self.tokenId = tokenId
        self.networkId = networkId
        self.userWalletId = userWalletId
        self.derivationPath = derivationPath
    }
}

// MARK: - Parsing

extension StakingDeeplink {
    init(link: DeeplinkURL) throws {
        let query = link.query

        tokenId = try query.required(Shared.tokenId, lowercased: true)
        networkId = try query.required(Shared.networkId, lowercased: true)
        userWalletId = query.unchecked(Shared.userWalletId)
        derivationPath = query.unchecked(Shared.derivationPath)
    }
}

// MARK: - Navigation

extension StakingDeeplink {
    @MainActor
    func makeOptions() -> StakingDetailsCoordinator.Options? {
        guard
            let target = DeeplinkWalletModelLocator().findTarget(
                userWalletId: userWalletId,
                tokenId: tokenId,
                networkId: networkId,
                derivationPath: derivationPath,
                requiring: .staking
            ),
            TokenActionAvailabilityProvider(
                userWalletInfo: target.userWalletModel.userWalletInfo,
                walletModel: target.walletModel
            ).isStakeFeatureAvailable,
            let stakingManager = target.walletModel.stakingManager
        else {
            return nil
        }

        let input = SendInput(userWalletInfo: target.userWalletModel.userWalletInfo, walletModel: target.walletModel)
        return StakingDetailsCoordinator.Options(sendInput: input, manager: stakingManager)
    }
}
