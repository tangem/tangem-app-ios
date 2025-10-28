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
    let persistentBlockchains: [TokenItem]
    let shouldLoadExpressAvailability: Bool
    let hardwareLimitationsUtil: HardwareLimitationsUtil
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
        let userTokensRepository = DummyUserTokensRepository()

        return AccountsAwareUserTokensManager(
            userWalletId: userWalletId,
            userTokensRepository: userTokensRepository,
            walletModelsManager: walletModelsManager,
            derivationInfo: derivationInfo,
            existingCurves: existingCurves,
            persistentBlockchains: persistentBlockchains,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hardwareLimitationsUtil: hardwareLimitationsUtil
        )
    }
}
