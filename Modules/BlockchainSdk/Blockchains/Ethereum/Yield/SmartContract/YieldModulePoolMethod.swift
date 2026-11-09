//
//  YieldModulePoolMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldModulePoolMethod {}

extension YieldModulePoolMethod: SmartContractMethod {
    public var methodId: String { "0x16f0115b" }
    public var data: Data { Data(hex: methodId) }
}
