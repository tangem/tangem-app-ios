//
//  UTXOSelector.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

public protocol UtxoSelectorInterface {
    func select(from utxos: [HDUnspentTransaction], targetValue: UInt64) throws -> (utxos: [HDUnspentTransaction], fee: UInt64)
}
