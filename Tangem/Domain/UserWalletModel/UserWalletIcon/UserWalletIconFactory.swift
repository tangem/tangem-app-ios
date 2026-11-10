//
//  UserWalletIconFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets

protocol UserWalletIconFactory {
    func icon(for walletInfo: WalletInfo) -> UserWalletIcon
}

struct CommonUserWalletIconFactory {}

extension CommonUserWalletIconFactory: UserWalletIconFactory {
    func icon(for walletInfo: WalletInfo) -> UserWalletIcon {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            .loadable(CardImageProvider(card: cardInfo.card))
        case .mobileWallet:
            .content(.image(Assets.MobileWallet.mobileWalletInFrame.uiImage))
        }
    }
}
