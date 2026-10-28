//
//  WrappedNativeMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct WrappedNativeMethod {}

extension WrappedNativeMethod: SmartContractMethod {
    public var methodId: String { "0xeb6d3a11" }
    public var data: Data { Data(hex: methodId) }
}
