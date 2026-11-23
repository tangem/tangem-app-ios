//
//  SmartContractMethodParameterType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum SmartContractMethodParameterType {
    case bytes(Data)
    case uint256(BigUInt)
}
