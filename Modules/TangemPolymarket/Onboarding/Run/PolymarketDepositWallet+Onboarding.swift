//
//  PolymarketDepositWallet+Onboarding.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketDepositWallet {
    func ensureMatches(derived: String) throws(PolymarketOnboardingError) {
        guard let address else { return }

        guard address.caseInsensitiveCompare(derived) == .orderedSame else {
            PolymarketLogger.error(
                "The backend reports deposit wallet \(address), locally derived \(derived)",
                error: PolymarketOnboardingError.addressMismatch
            )
            throw .addressMismatch
        }
    }
}
