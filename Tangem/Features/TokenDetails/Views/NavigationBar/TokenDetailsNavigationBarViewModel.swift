//
//  TokenDetailsNavigationBarViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemAccounts.AccountIconView
import TangemLocalization
import enum TangemUI.ThumbnailWalletViewType

struct TokenDetailsNavigationBarViewModel: Equatable {
    let title: Self.Title
    let subtitle: String
}

extension TokenDetailsNavigationBarViewModel {
    struct Title: Equatable {
        let tokenName: String
        let storedIn: TokenStorage
    }

    enum TokenStorage: Equatable {
        case account(icon: AccountIconView.ViewData, name: String)
        case wallet(name: String, icon: ThumbnailWalletViewType?)
        case singleWallet

        var preposition: String? {
            switch self {
            case .account, .wallet: Localization.commonIn
            case .singleWallet: nil
            }
        }
    }
}
