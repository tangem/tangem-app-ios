//
//  TokenItemViewState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemViewState {
    case notLoaded
    case noDerivation
    case loading
    case loaded
    case noAccount(message: String)
    case networkError(Error)

    init(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created:
            self = .notLoaded
        case .idle:
            self = .loaded
        case .loading:
            self = .loading
        case .noAccount(let message):
            self = .noAccount(message: message)
        case .failed(let error):
            self = .networkError(error)
        case .noDerivation:
            self = .noDerivation
        }
    }
}
