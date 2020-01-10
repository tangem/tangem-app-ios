//
//  UnspendTransaction.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation

public struct HDUnspentTransaction {
    public let output: TransactionOutput
    public let outpoint: TransactionOutPoint
    
    public init(output: TransactionOutput, outpoint: TransactionOutPoint) {
        self.output = output
        self.outpoint = outpoint
    }
}
