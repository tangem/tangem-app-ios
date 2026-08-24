//
//  TransactionDetailsDebugInfoFactory.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import Foundation
import BlockchainSdk

enum TransactionDetailsDebugInfoFactory {
    static func make(for record: TransactionRecord) -> TransactionDetailsDebugInfo {
        let isSynthetic = ExpressSyntheticTxHelper.isSyntheticIdentifier(record.hash)

        let source: String
        let operation: String

        switch record.expressExtraInfo {
        case .exchange:
            operation = "Swap"
            source = isSynthetic ? "Express (synthetic)" : "BSDK + Express (merged)"
        case .onramp:
            operation = "Onramp"
            source = isSynthetic ? "Express (synthetic)" : "BSDK + Express (merged)"
        case nil:
            operation = "On-chain"
            source = "BSDK (on-chain)"
        }

        return TransactionDetailsDebugInfo(
            summary: [
                .init(title: "Source", value: source),
                .init(title: "Operation", value: operation),
            ],
            dump: ReflectionDump.text(for: record)
        )
    }
}
#endif
