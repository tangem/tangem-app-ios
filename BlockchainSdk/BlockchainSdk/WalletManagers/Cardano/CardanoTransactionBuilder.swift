//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class CardanoTransactionBuilder {
    var unspentOutputs: [AdaliteUnspentOutput]? = nil
    let kDecimalNumber: Int16 = 6
    let kProtocolMagic: UInt64 = 764824073
    
    public func buildForSign(transaction: Transaction) -> [Data]? {
        
    }
    
    public func buildForSend(transaction: Transaction, signature: Data) -> Data? {
        
    }
}

