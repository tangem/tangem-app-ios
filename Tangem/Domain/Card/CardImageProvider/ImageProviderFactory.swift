//
//  ImageProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletImageProviderFactory {
    func imageProvider(for walletInfo: WalletInfo) -> WalletImageProviding
}

struct CommonWalletImageProviderFactory {}

extension CommonWalletImageProviderFactory: WalletImageProviderFactory {
    func imageProvider(for walletInfo: WalletInfo) -> any WalletImageProviding {
        switch walletInfo.type {
        case .card(let cardInfo):
            CardImageProvider(card: cardInfo.card)
        case .hot:
            HotWalletImageProvider()
        }
    }
}
