//
//  SafeGetOwnersRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SafeGetOwnersRequest: SmartContractRequest {
    let contractAddress: String
    private let method: SmartContractMethod
    var encodedData: String { method.encodedData }

    init(contractAddress: String) {
        self.contractAddress = contractAddress
        method = SafeGetOwnersMethod()
    }
}

/// `getOwners()` of a Safe.
struct SafeGetOwnersMethod: SmartContractMethod {
    var methodId: String { "0xa0e67e2b" }
    var data: Data { defaultData() }
}
