//
//  AccountSelectorWalletItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import TangemFoundation
import TangemMacro
import TangemUI

struct AccountSelectorWalletItem: Identifiable, Equatable {
    let id: String
    let name: String
    let wallet: UserWallet
    let mainAccount: any CryptoAccountModel
    let domainModel: any UserWalletModel
    let walletImageProvider: WalletImageProviding
    let accountAvailability: AccountAvailability

    @CaseFlagable
    enum UserWallet: Equatable {
        case active(ActiveWallet)
        case locked(LockedWallet)

        struct ActiveWallet: Equatable {
            let id: String
            let tokensCount: String
            @IgnoredEquatable
            var formattedBalanceTypePublisher: AnyPublisher<LoadableBalanceView.State, Never>
        }

        struct LockedWallet: Equatable {
            let cardsLabel: String
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.wallet == rhs.wallet && lhs.accountAvailability == rhs.accountAvailability
    }
}

extension AccountSelectorWalletItem {
    init(
        userWallet: any UserWalletModel,
        cryptoAccountModel: any CryptoAccountModel,
        isLocked: Bool,
        accountAvailability: AccountAvailability = .available
    ) {
        id = userWallet.userWalletId.stringValue
        name = userWallet.name
        walletImageProvider = userWallet.walletImageProvider
        mainAccount = cryptoAccountModel
        domainModel = userWallet
        self.accountAvailability = accountAvailability

        // Ternary avoided for clarity
        wallet = if isLocked {
            .locked(.init(
                cardsLabel: userWallet.cardSetLabel
            ))
        } else {
            .active(.init(
                id: userWallet.userWalletId.stringValue,
                tokensCount: Localization.commonTokensCount(cryptoAccountModel.walletModelsManager.walletModels.count),
                formattedBalanceTypePublisher: cryptoAccountModel.fiatTotalBalanceProvider.totalFiatBalancePublisher
            ))
        }
    }
}
