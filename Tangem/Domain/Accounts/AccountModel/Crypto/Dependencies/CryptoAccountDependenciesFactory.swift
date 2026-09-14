//
//  CryptoAccountDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Produces required dependencies for a specific account identified by its derivation identity.
protocol CryptoAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIdentity derivationIdentity: CryptoAccountDerivationIdentity
    ) -> CryptoAccountDependencies
}
