//
//  FeedWidgetsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeedWidgetsRoutable: AnyObject {
    func openEarn()
    func openTangemPay(_ entry: FeedTangemPayEntry)
    func openReferral(
        candidates: [FeedReferralWalletCandidate],
        candidatesPublisher: AnyPublisher<[FeedReferralWalletCandidate], Never>,
        resolveAvailableWallet: @escaping (UserWalletId) -> UserWalletModel?,
        onDismiss: @escaping (UserWalletId) -> Void
    )
    func openForYou()
    func openAddAccount(candidates: [FeedAccountCandidate])
    func openPolymarketMain(wallet: UserWalletModel)
    func openCollectibles(wallets: [UserWalletModel], isRegionRestricted: Bool)
}

struct FeedReferralWalletCandidate: Equatable {
    enum State: Equatable {
        case available(reward: String)
        case unavailable
        case loading
        case failure
    }

    let wallet: UserWalletModel
    let state: State

    var reward: String? {
        guard case .available(let reward) = state else { return nil }
        return reward
    }

    var isAvailable: Bool { reward != nil }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wallet === rhs.wallet && lhs.state == rhs.state
    }
}
