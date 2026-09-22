//
//  JointAccountDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Produces the dependencies of a joint account identified by its derivation identity; the joint counterpart of
/// `CryptoAccountDependenciesFactory`.
protocol JointAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIdentity derivationIdentity: CryptoAccountDerivationIdentity
    ) -> JointAccountDependencies
}
