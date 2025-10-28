//
//  UserTokenListExternalParametersHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Shares some common logic for providing external parameters to `UserTokenListConverter` and/or `CryptoAccountsNetworkMapper`.
enum UserTokenListExternalParametersHelper {
    static func provideTokenListAddresses(
        with walletModels: [any WalletModel],
        tokenListNotifyStatusValue: Bool
    ) -> [WalletModelId: [String]]? {
        guard tokenListNotifyStatusValue else {
            return nil
        }

        return walletModels
            .reduce(into: [:]) { partialResult, walletModel in
                let addresses = walletModel.addresses.map(\.value)
                partialResult[walletModel.id] = addresses
            }
    }

    static func provideTokenListNotifyStatusValue(
        with userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    ) -> Bool {
        return userTokensPushNotificationsManager.status.isActive
    }
}
