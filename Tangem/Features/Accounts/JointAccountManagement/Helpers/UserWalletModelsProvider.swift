//
//  UserWalletModelsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum UserWalletModelsProvider {
    @Injected(\.userWalletRepository) private static var userWalletRepository: UserWalletRepository

    static func available(from userWalletModels: [any UserWalletModel]) -> [any UserWalletModel] {
        userWalletModels.filter { !$0.isUserWalletLocked }
    }

    static func `default`(from availableUserWalletModels: [any UserWalletModel]) -> (any UserWalletModel)? {
        let selectedUserWalletId = userWalletRepository.selectedModel?.userWalletId

        return availableUserWalletModels.first { $0.userWalletId == selectedUserWalletId }
            ?? availableUserWalletModels.first
    }
}
