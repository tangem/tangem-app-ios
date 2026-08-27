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
        shouldIncludeAddresses: Bool
    ) -> [WalletModelId: [String]]? {
        guard shouldIncludeAddresses else {
            return nil
        }

        return walletModels
            .reduce(into: [:]) { partialResult, walletModel in
                partialResult[walletModel.id] = walletModel.addressesString
            }
    }
}
