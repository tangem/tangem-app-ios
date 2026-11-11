//
//  EthereumOptimisticRollupSmartContractMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum EthereumOptimisticRollupSmartContractMethod: SmartContractTargetMethodType {
    case getL1Fee(data: Data)
    case getL1GasUsed(data: Data)
    case l1BaseFee
    case getOperatorFee(gasUsed: BigUInt)

    var methodName: String {
        switch self {
        case .getL1Fee:
            return "getL1Fee"
        case .getL1GasUsed:
            return "getL1GasUsed"
        case .l1BaseFee:
            return "l1BaseFee"
        case .getOperatorFee:
            return "getOperatorFee"
        }
    }

    var parameters: [SmartContractMethodParameterType] {
        switch self {
        case .getL1Fee(let data):
            return [.bytes(data)]
        case .getL1GasUsed(let data):
            return [.bytes(data)]
        case .l1BaseFee:
            return []
        case .getOperatorFee(let gasUsed):
            return [.uint256(gasUsed)]
        }
    }
}
