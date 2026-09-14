//
//  SafeNonceRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SafeNonceRequest: SmartContractRequest {
    let contractAddress: String
    private let method: SmartContractMethod
    var encodedData: String { method.encodedData }

    init(contractAddress: String) {
        self.contractAddress = contractAddress
        method = SafeNonceMethod()
    }
}

/// `nonce()` of a Safe — the selector every `nonce()` has, `0xaffed0e0`.
struct SafeNonceMethod: SmartContractMethod {
    var methodId: String { "0xaffed0e0" }
    var data: Data { defaultData() }
}
