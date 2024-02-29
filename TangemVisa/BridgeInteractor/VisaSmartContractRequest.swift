//
//  VisaSmartContractRequest.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct VisaSmartContractRequest: SmartContractRequest {
    var contractAddress: String

    private let method: SmartContractMethod

    var encodedData: String { method.encodedData }

    init(contractAddress: String, method: SmartContractMethod) {
        self.contractAddress = contractAddress
        self.method = method
    }
}
