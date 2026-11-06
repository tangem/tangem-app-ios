//
//  AccountPickerAccountAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts

protocol AccountPickerAccountAvailabilityProvider {
    func availability(of account: some BaseAccountModel, in userWalletModel: some UserWalletModel) -> SelectorAvailability
}

extension AccountPickerAccountAvailabilityProvider where Self == AllAvailableAccountPickerAvailabilityProvider {
    static func allAvailable() -> Self {
        AllAvailableAccountPickerAvailabilityProvider()
    }
}

struct AllAvailableAccountPickerAvailabilityProvider: AccountPickerAccountAvailabilityProvider {
    func availability(of account: some BaseAccountModel, in userWalletModel: some UserWalletModel) -> SelectorAvailability {
        .available
    }
}
