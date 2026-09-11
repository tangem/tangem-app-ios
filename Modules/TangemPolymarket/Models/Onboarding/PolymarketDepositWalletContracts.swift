//
//  PolymarketDepositWalletContracts.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Polygon mainnet. The factory deploys beacon proxies rather than the UUPS layout the onboarding spec
/// describes, so the init code below is the beacon one, taken verbatim from deployments the factory made.
enum PolymarketDepositWalletContracts {
    /// Published by Polymarket; deploys the wallet and is the CREATE2 deployer the address is derived from.
    static let factory = "0x00000000000Fb5C9ADea0298D729A0CB3823Cc07"

    /// Read off the factory through the beacon selector `0x49493a4d`; every wallet it deployed points here.
    static let beacon = "0x7A18EDfe055488A3128f01F563e5B479D92ffc3a"

    /// Creation logic; its third byte carries the 64-byte argument length, invariant here.
    static let beaconInitPrefix = "0x6100923d8160233d3973"

    /// Beacon-slot store plus the 82-byte proxy runtime the creation logic returns.
    static let beaconInitSuffix = "0x60195155f3" +
        "363d3d373d3d363d602036600436635c60da1b60e01b36527f" +
        "a3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50" +
        "545afa5036515af43d6000803e604d573d6000fd5b3d6000f3"
}
