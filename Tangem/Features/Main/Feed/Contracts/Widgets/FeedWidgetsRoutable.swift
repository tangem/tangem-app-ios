//
//  FeedWidgetsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedWidgetsRoutable: AnyObject {
    func openEarn()
    func openTangemPay(_ entry: FeedTangemPayEntry)
    func openReferral(wallet: UserWalletModel)
    func openForYou()
    func openAddAccount(candidates: [FeedAccountCandidate])
}
