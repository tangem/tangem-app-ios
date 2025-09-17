//
//  CryptoAccountsRemoteIdentifierBuilding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Builds remote account identifiers for local account models.
protocol CryptoAccountsRemoteIdentifierBuilding {
    associatedtype Input
    associatedtype Output

    func build(from input: Input) -> Output
}
