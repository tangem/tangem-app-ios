//
//  AccountModelsReordering.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol AccountModelsReordering {
    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws
}
