//
//  CommonAccountUserTokensManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonAccountUserTokensManagerFactory {}

// MARK: - AccountUserTokensManagerFactory protocol conformance

extension CommonAccountUserTokensManagerFactory: AccountUserTokensManagerFactory {
    func makeUserTokensManager(
        forAccountWithDerivationIndex derivationIndex: Int,
        walletModelsManager: WalletModelsManager
    ) -> UserTokensManager {
        fatalError("\(#function) not implemented yet!")
    }
}
