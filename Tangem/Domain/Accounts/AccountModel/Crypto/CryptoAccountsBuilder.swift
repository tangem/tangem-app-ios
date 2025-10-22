//
//  CryptoAccountsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import CombineExt

struct CryptoAccountsBuilder {
    private let globalState: CryptoAccounts.State

    init(globalState: CryptoAccounts.State) {
        self.globalState = globalState
    }

    func build(from accounts: [any CryptoAccountModel]) -> CryptoAccounts {
        switch (accounts.count, globalState) {
        case (0, _):
            preconditionFailure("CryptoAccounts must be initialized with at least one CryptoAccountModel")
        case (1, .single):
            return .single(accounts[0])
        default:
            // Even when there is a single account but the global state is `.multiple`,
            // that single account must be represented as `.multiple` in order to be rendered in the UI correctly
            return .multiple(accounts)
        }
    }
}
