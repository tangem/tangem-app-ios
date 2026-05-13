//
//  UTXOResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct UTXOResponse {
    let outputs: [UnspentOutput]
    let pending: [TransactionRecord]

    init(outputs: [UnspentOutput], pending: [TransactionRecord]) {
        self.outputs = outputs
        self.pending = pending
    }
}
