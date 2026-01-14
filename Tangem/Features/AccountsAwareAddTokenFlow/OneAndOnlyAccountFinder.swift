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

        guard
            let userWalletModel = availableUserWalletModels.singleElement,
            let accountModel = userWalletModel.accountModelsManager.accountModels.firstStandard()
        else {
            return nil
        }

        let cryptoAccountModel = switch accountModel {
        case .standard(.multiple(let cryptoAccountModels)):
            cryptoAccountModels.singleElement
        case .standard(.single(let model)):
            model
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
