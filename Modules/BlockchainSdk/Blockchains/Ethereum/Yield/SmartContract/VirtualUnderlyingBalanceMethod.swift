//
//  VirtualUnderlyingBalanceMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct VirtualUnderlyingBalanceMethod {
    let assetContractAddress: String
}

extension VirtualUnderlyingBalanceMethod: SmartContractMethod {
    public var methodId: String { "0x6fb07f96" }
    public var data: Data { defaultData() }
}
