//
//  PolymarketUtilities.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum PolymarketUtilities {}

public extension PolymarketUtilities {
    static let mandatoryCurve: EllipticCurve = .secp256k1

    static let derivationPath = try! DerivationPath(rawPath: "m/44'/60'/999997'/0/0")
}
