//
//  OneAndOnlyAccountFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts

/// Utility to find the single account when there's only one available
enum OneAndOnlyAccountFinder {
    /// Finds the single account if there's exactly one available user wallet with one account
    /// - Parameter userWalletModels: The list of user wallet models to check
    /// - Returns: The single account cell model if there's exactly one, nil otherwise
    static func find(in userWalletModels: [UserWalletModel]) -> AccountSelectorCellModel? {
        let availableUserWalletModels = userWalletModels.filter { !$0.isUserWalletLocked }

        guard let userWalletModel = availableUserWalletModels.singleElement else {
            return nil
        }

        let cryptoAccountModel: (any CryptoAccountModel)?
        switch userWalletModel.accountModelsManager.accountModels.first {
        case .standard(let cryptoAccounts):
            switch cryptoAccounts {
            case .multiple(let cryptoAccountModels):
                cryptoAccountModel = cryptoAccountModels.singleElement

            case .single(let model):
                cryptoAccountModel = model
            }

        case nil:
            cryptoAccountModel = nil
        }

        guard let cryptoAccountModel else {
            return nil
        }

        // Create wallet item since we have exactly one wallet
        let walletItem = AccountSelectorWalletItem(
            userWallet: userWalletModel,
            cryptoAccountModel: cryptoAccountModel,
            isLocked: false
        )

        return .wallet(walletItem)
    }
}
