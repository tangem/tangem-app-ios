//
//  CommonAccountUserTokensManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

struct CommonAccountUserTokensManagerFactory {
    let userTokenListManager: UserTokenListManager
    let derivationStyle: DerivationStyle?
    let derivationManager: DerivationManager?
    let existingCurves: [EllipticCurve]
    let shouldLoadExpressAvailability: Bool
    let areLongHashesSupported: Bool
}

// MARK: - AccountUserTokensManagerFactory protocol conformance

extension CommonAccountUserTokensManagerFactory: AccountUserTokensManagerFactory {
    func makeUserTokensManager(
        forAccountWithDerivationIndex derivationIndex: Int,
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager
    ) -> UserTokensManager {
        let derivationInfo = AccountsAwareUserTokensManager.DerivationInfo(
            derivationIndex: derivationIndex,
            derivationStyle: derivationStyle,
            derivationManager: derivationManager
        )

        return AccountsAwareUserTokensManager(
            userWalletId: userWalletId,
            userTokenListManager: userTokenListManager,
            walletModelsManager: walletModelsManager,
            derivationInfo: derivationInfo,
            existingCurves: existingCurves,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            areLongHashesSupported: areLongHashesSupported
        )
    }
}
