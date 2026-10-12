//
//  FeatureDerivationPaths.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
//  Every feature that needs its own account derives it from `m/44'/60'`, taking a block of
//  100 account indexes reserved from the top so the blocks never meet the ones BIP-44 hands
//  out to wallets. A feature spends its block from the last index down.
//
//      999900' - 999999'   Tangem Pay
//      999800' - 999899'   Polymarket
//      999700' - 999799'   Gatcha
//
//  The paths live here as raw strings because this module deliberately has no dependencies:
//  each feature builds its own `DerivationPath` out of them.
//

import Foundation

public enum FeatureDerivationPaths {
    public static let tangemPay = "m/44'/60'/999999'/0/0"
    public static let polymarket = "m/44'/60'/999899'/0/0"
}
