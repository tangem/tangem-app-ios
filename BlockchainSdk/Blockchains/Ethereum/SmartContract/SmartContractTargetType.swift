//
//  SmartContractMethodType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SmartContractTargetType {
    var contactAddress: String { get }
    var methodName: String { get }
    var parameters: [SmartContractMethodParameterType] { get }
}
