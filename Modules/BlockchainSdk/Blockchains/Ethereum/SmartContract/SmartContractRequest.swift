//
//  SmartContractRequest.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol SmartContractRequest {
    var contractAddress: String { get }
    var encodedData: String { get }
}
