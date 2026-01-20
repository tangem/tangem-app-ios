//
//  SmartContractTargetMethodType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SmartContractTargetMethodType {
    var methodName: String { get }
    var parameters: [SmartContractMethodParameterType] { get }
}
