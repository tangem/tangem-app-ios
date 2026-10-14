//
//  FeedHostRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedHostRoutable: AnyObject {
    func openTangemPay(entry: FeedTangemPayEntry)
    func openManageTokens(for account: any CryptoAccountModel, in userWalletModel: UserWalletModel)
    func openPolymarket(userWalletModel: UserWalletModel)
    func openCollectibles(with options: CollectiblesCoordinator.Options)
}
