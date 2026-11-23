//
//  UserWalletSelectorUserWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol UserWalletSelectorUserWalletsProvider {
    var userWalletModels: [any UserWalletModel] { get }
}

// MARK: - Factories

extension UserWalletSelectorUserWalletsProvider where Self == AllUserWalletsProvider {
    static func allUserWallets() -> Self {
        AllUserWalletsProvider()
    }
}

extension UserWalletSelectorUserWalletsProvider where Self == StaticUserWalletsProvider {
    static func userWallet(_ userWalletModel: any UserWalletModel) -> Self {
        StaticUserWalletsProvider(userWalletModels: [userWalletModel])
    }
}

// MARK: - Implementations

struct AllUserWalletsProvider: UserWalletSelectorUserWalletsProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var userWalletModels: [any UserWalletModel] {
        userWalletRepository.models
    }
}

struct StaticUserWalletsProvider: UserWalletSelectorUserWalletsProvider {
    let userWalletModels: [any UserWalletModel]
}
