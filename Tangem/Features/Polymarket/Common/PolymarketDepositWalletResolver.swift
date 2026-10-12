//
//  PolymarketDepositWalletResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketDepositWalletResolver {
    let walletService: PolymarketDepositWalletService
    let ownerAddressProvider: PolymarketOwnerAddressProviding

    func resolve() async throws -> PolymarketDepositWalletAddresses {
        guard let ownerAddress = ownerAddressProvider.getOwnerAddress() else {
            throw PolymarketAccountFundsError.ownerKeyUnavailable
        }

        let derived = try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)
        let stored = try await walletService.depositWalletState(ownerAddress: ownerAddress)

        try stored.ensureMatches(derived: derived)

        guard stored.address != nil, stored.status == .readyToTrade else {
            throw PolymarketAccountFundsError.depositWalletNotReadyToTrade(stored.status)
        }

        return PolymarketDepositWalletAddresses(owner: ownerAddress, depositWallet: derived)
    }
}

struct PolymarketDepositWalletAddresses: Equatable {
    let owner: String
    let depositWallet: String
}
