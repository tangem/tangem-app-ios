//
//  YieldSmartContractRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldSmartContractRequest: SmartContractRequest {
    public let contractAddress: String
    private let method: SmartContractMethod

    public var encodedData: String { method.encodedData }

    public init(contractAddress: String, method: SmartContractMethod) {
        self.contractAddress = contractAddress
        self.method = method
    }
}
