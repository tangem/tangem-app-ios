//
//  EnterProtocolByOwnerWithNativeMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct EnterProtocolByOwnerWithNativeMethod {
    public init() {}
}

extension EnterProtocolByOwnerWithNativeMethod: SmartContractMethod {
    public var methodId: String { "0x0921ecd4" }
    public var data: Data { Data(hex: methodId) }
}
