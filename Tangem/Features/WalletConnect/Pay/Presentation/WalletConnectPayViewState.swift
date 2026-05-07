//
//  WalletConnectPayViewState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension WalletConnectPayViewModel {
    enum Step: Equatable {
        case loading
        case options
        case dataCollection(URL)
        case signing
        case result(WalletConnectPayResultState)
        case error(String)
    }
}

struct WalletConnectPayTarget: Identifiable, Equatable {
    let id: String
    let userWalletId: UserWalletId
    let accountId: String
    let title: String
    let userWalletName: String
}

struct WalletConnectPayResultState: Equatable {
    enum Kind: Equatable {
        case success
        case processing
        case failed
        case expired
        case cancelled
    }

    let kind: Kind
    let title: String
    let message: String
}
