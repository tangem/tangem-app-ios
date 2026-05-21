//
//  FactoryImplementationMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct FactoryImplementationMethod {}

extension FactoryImplementationMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `implementation()` method.
    public var methodId: String { "0x5c60da1b" }
    public var data: Data { Data(hex: methodId) }
}
