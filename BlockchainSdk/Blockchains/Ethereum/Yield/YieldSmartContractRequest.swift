//
//  YieldSmartContractRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldSmartContractRequest: SmartContractRequest {
    let contractAddress: String
    private let method: SmartContractMethod

    var encodedData: String { method.encodedData }

    init(contractAddress: String, method: SmartContractMethod) {
        self.contractAddress = contractAddress
        self.method = method
    }
}
