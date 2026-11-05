//
//  JointOperationSyntheticTxHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct JointOperationSyntheticTxHelper {
    static let methodName = "jointOperation"

    private static let prefix = "JointOperationSyntheticTx_"

    private let operationId: String

    init(operationId: String) {
        self.operationId = operationId
    }

    func makeSyntheticTxIdentifier() -> String {
        Self.prefix + operationId
    }

    static func isSyntheticIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix(prefix)
    }
}
