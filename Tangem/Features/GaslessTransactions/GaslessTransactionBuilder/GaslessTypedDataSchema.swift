//
//  GaslessTypedDataSchema.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum GaslessTypedDataSchema {
    static let domainName = "Tangem7702GaslessExecutor"
    static let domainVersion = "1"
    static let singlePrimaryType = "GaslessTransaction"
    static let batchPrimaryType = "GaslessBatchTransaction"
    static let primaryTypes: Set<String> = [singlePrimaryType, batchPrimaryType]
}
