//
//  WithdrawAndDeactivateNativeMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct WithdrawAndDeactivateNativeMethod {
    public init() {}
}

extension WithdrawAndDeactivateNativeMethod: SmartContractMethod {
    public var methodId: String { "0x4423380d" }
    public var data: Data { Data(hex: methodId) }
}
