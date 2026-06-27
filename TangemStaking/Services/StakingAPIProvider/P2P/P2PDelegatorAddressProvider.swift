//
//  P2PDelegatorAddressProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Supplies the full set of Ethereum delegator addresses across all accounts for the P2P batch balances request.
/// Implemented on the app side (it reads the wallet models), injected here across the module boundary.
public protocol P2PDelegatorAddressProvider {
    /// The current snapshot of every Ethereum delegator address across all accounts.
    func delegatorAddresses() -> [String]

    /// Emits whenever the set of Ethereum delegator addresses changes (accounts/wallets added or removed),
    /// driving the batch service to proactively refresh balances.
    var delegatorAddressesPublisher: AnyPublisher<[String], Never> { get }
}
