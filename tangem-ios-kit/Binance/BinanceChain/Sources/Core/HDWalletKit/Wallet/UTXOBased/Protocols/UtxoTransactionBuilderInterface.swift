//
//  UtxoTransactionBuilder.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

public protocol UtxoTransactionBuilderInterface {
    func build(destinations: [(address: Address, amount: UInt64)], utxos: [HDUnspentTransaction]) throws -> UnsignedTransaction
}
