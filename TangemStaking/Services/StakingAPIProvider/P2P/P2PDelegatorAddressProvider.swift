//
//  P2PDelegatorAddressProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Supplies the full set of Ethereum delegator addresses across all accounts for the P2P batch balances request.
/// Implemented on the app side (it reads the wallet models), injected here across the module boundary.
public protocol P2PDelegatorAddressProvider {
    func delegatorAddresses() -> [String]
}
