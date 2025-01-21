//
//  AlephiumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
final class AlephiumTransactionBuilder {
    // MARK: - Private Properties

    private var utxo: [AlephiumUTXO] = []

    // MARK: - Public Implementation

    func update(utxo: [AlephiumUTXO]) {
        self.utxo = utxo
    }

    // MARK: - Private Implementation
}
