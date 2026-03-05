//
//  WalletCreationHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemFoundation

struct WalletCreationHelper {
    private let userWalletConfig: UserWalletConfig
    private let userWalletId: UserWalletId
    private let userWalletName: String
    private let networkService: WalletsNetworkService

    init(
        userWalletId: UserWalletId,
        userWalletName: String?,
        userWalletConfig: UserWalletConfig,
        networkService: WalletsNetworkService
    ) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
        self.userWalletName = userWalletName ?? UserWalletNameIndexationHelper().suggestedName(userWalletConfig: userWalletConfig)
        self.networkService = networkService
    }

    func createWallet() async throws {
        let name = userWalletName
        let identifier = userWalletId.stringValue
        let contextBuilder = userWalletConfig.contextBuilder
        let context = contextBuilder
            .enrich(withName: name)
            .enrich(withIdentifier: identifier)
            .enrichReferral()
            .build()

        try await networkService.createWallet(with: context)
    }

    func updateWallet() async throws {
        let name = userWalletName
        let contextBuilder = userWalletConfig.contextBuilder
        let context = contextBuilder
            .enrich(withName: name)
            .build()

        try await networkService.updateWallet(context: context)
    }
}

// MARK: - Convenience initializers

extension WalletCreationHelper {
    /// Convenience initializer for cases when the network service doesn't need to be injected from outside.
    init(
        userWalletId: UserWalletId,
        userWalletName: String?,
        userWalletConfig: UserWalletConfig
    ) {
        self.init(
            userWalletId: userWalletId,
            userWalletName: userWalletName,
            userWalletConfig: userWalletConfig,
            networkService: CommonWalletsNetworkService(userWalletId: userWalletId)
        )
    }
}
