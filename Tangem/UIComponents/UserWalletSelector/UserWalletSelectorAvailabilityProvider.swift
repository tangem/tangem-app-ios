//
//  UserWalletSelectorAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

protocol UserWalletSelectorAvailabilityProvider {
    func availability(of userWalletModel: any UserWalletModel) -> SelectorAvailability
}

extension UserWalletSelectorAvailabilityProvider where Self == LockStateUserWalletSelectorAvailabilityProvider {
    static func lockState() -> Self {
        LockStateUserWalletSelectorAvailabilityProvider()
    }
}

extension UserWalletSelectorAvailabilityProvider where Self == AccountCreationUserWalletSelectorAvailabilityProvider {
    static func accountCreation(_ accountType: AccountType) -> Self {
        AccountCreationUserWalletSelectorAvailabilityProvider(accountType: accountType)
    }
}

struct LockStateUserWalletSelectorAvailabilityProvider: UserWalletSelectorAvailabilityProvider {
    func availability(of userWalletModel: any UserWalletModel) -> SelectorAvailability {
        userWalletModel.isUserWalletLocked ? .locked : .available
    }
}

struct AccountCreationUserWalletSelectorAvailabilityProvider: UserWalletSelectorAvailabilityProvider {
    let accountType: AccountType

    func availability(of userWalletModel: any UserWalletModel) -> SelectorAvailability {
        if userWalletModel.isUserWalletLocked {
            return .locked
        }

        if AccountModelUtils.isAccountsLimitReached(for: accountType, in: userWalletModel.accountModelsManager.accountModels) {
            return .unavailable(.accountsLimitReached(for: accountType))
        }

        return .available
    }
}
