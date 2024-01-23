//
//  CardInitializationValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardInitializationValidator {
    let expectedCurves: [EllipticCurve]

    func validateWallets(_ wallets: [Card.Wallet]) -> Bool {
        let createdCurves = Set(wallets.map { $0.curve })

        // check that all curves created without duplicates
        guard wallets.count == expectedCurves.count,
              createdCurves == Set(expectedCurves) else {
            return false
        }

        return true
    }
}
