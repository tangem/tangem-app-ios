//
//  UnsignedTransactionData.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum UnsignedTransactionData: Hashable, Equatable {
    case raw(String)
    case compiledEthereum(EthereumCompiledTransactionData)
}
