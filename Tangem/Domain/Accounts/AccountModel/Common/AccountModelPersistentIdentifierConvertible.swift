//
//  AccountModelPersistentIdentifierConvertible.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Represents account identifier that can be converted to a persistent identifier.
protocol AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> AnyHashable
}
