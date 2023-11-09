//
//  ExpressManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// ExpressManager needed for:
/// 1. Keep in the our state which items(Wallet) want to be swapped
/// 2. Keep in the our state which amount want to be swapped
/// 3. Keep in the our state which provider should be use
/// 4. Make a necessary requests to get state
public protocol ExpressManager {
    var amount: Decimal? { get set }
    var fromWallet: ExpressWallet { get set }
    var toWallet: ExpressWallet?  { get set }
    var provider: ExpressProvider? { get set }

    func refresh() async -> SwappingAvailabilityState
}
