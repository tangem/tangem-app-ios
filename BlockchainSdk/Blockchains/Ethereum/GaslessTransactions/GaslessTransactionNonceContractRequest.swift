//
//  GaslessTransactionNonceContractRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct GaslessTransactionNonceContractRequest: SmartContractRequest {
    public var contractAddress: String
    public var encodedData: String
}
