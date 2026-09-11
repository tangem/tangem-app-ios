//
//  SafeGetThresholdRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SafeGetThresholdRequest: SmartContractRequest {
    let contractAddress: String
    private let method: SmartContractMethod
    var encodedData: String { method.encodedData }

    init(contractAddress: String) {
        self.contractAddress = contractAddress
        method = SafeGetThresholdMethod()
    }
}

/// `getThreshold()` of a Safe.
struct SafeGetThresholdMethod: SmartContractMethod {
    var methodId: String { "0xe75235b8" }
    var data: Data { defaultData() }
}
