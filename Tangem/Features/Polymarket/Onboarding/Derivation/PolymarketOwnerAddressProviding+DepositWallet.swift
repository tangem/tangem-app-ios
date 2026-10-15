//
//  PolymarketOwnerAddressProviding+DepositWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPolymarket

enum PolymarketDepositWalletAddressError: Error {
    case ownerAddressUnavailable
}

extension PolymarketOwnerAddressProviding {
    func depositWalletAddress() throws -> String {
        guard let ownerAddress = getOwnerAddress() else {
            throw PolymarketDepositWalletAddressError.ownerAddressUnavailable
        }

        return try PolymarketDepositWalletDeriver.derive(ownerAddress: ownerAddress)
    }
}
