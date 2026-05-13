//
//  XRPTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct XRPTransactionParams: TransactionParams {
    var destinationTag: UInt32?
    var sequence: Int?

    public init(destinationTag: UInt32? = nil, sequence: Int? = nil) {
        self.destinationTag = destinationTag
        self.sequence = sequence
    }
}
