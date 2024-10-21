//
//  StellarTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

public typealias StellarMemo = Memo

public struct StellarTransactionParams: TransactionParams {
    public var memo: StellarMemo?
    
    public init(memo: StellarMemo? = nil) {
        self.memo = memo
    }
}
