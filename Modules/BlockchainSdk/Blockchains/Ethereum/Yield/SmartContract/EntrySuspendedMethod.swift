//
//  EntrySuspendedMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct EntrySuspendedMethod {
    let tokenContractAddress: String
}

extension EntrySuspendedMethod: SmartContractMethod {
    public var methodId: String { "0x729b4fc8" }
    public var data: Data { defaultData() }
}
