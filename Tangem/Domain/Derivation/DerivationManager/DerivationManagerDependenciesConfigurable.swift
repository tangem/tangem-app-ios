//
//  DerivationManagerDependenciesConfigurable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Represents an entity that can be configured with dependencies required for derivation management.
protocol DerivationManagerDependenciesConfigurable {
    func configure(with keysDerivingProvider: KeysDerivingProvider)
    func configure(with accountModelsManager: AccountModelsManager)
}
