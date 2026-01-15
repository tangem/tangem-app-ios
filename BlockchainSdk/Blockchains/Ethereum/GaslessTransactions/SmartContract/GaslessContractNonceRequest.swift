//
//  GaslessContractNonceRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GaslessContractNonceRequest: SmartContractRequest {
    public var contractAddress: String
    private let method: SmartContractMethod
    var encodedData: String { method.encodedData }

    init(contractAddress: String) {
        self.contractAddress = contractAddress
        method = GaslessContractNonceMethod()
    }
}

public struct GaslessContractNonceMethod: SmartContractMethod {
    public var methodId: String { "0xaffed0e0" }
    public var data: Data { defaultData() }
}
