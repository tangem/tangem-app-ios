//
//  FeedZoomSource.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedZoomSource: Hashable {
    case portfolioToken(walletID: AnyHashable, accountID: AnyHashable, tokenID: WalletModelId)
}
