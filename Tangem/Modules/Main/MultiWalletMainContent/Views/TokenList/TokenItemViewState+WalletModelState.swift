//
//  TokenItemViewState+WalletModelState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension TokenItemViewState {
    init(walletModelState: WalletModel.State) {
        switch walletModelState {
        case .created:
            self = .notLoaded
        case .idle:
            self = .loaded
        case .loading:
            self = .loading
        case .noAccount(let message, _):
            self = .noAccount(message: message)
        case .failed(let error):
            self = .networkError(error)
        case .noDerivation:
            self = .noDerivation
        }
    }
}
