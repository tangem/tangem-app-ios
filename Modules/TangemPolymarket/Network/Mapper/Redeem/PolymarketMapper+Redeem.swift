//
//  PolymarketMapper+Redeem.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension PolymarketMapper {
    func mapRedeemCall(
        _ response: PolymarketDTO.RedeemCallResponse,
        conditionId: String,
        isNegRisk: Bool
    ) throws(PolymarketRedeemError) -> PolymarketRelayedBatch.Call {
        let call = PolymarketRelayedBatch.Call(target: response.target, data: response.data)

        guard response.value == call.value else {
            throw .other(.decoding(field: "value", value: response.value))
        }

        let adapter = isNegRisk
            ? PolymarketApprovalContracts.negRiskCtfCollateralAdapter
            : PolymarketApprovalContracts.ctfCollateralAdapter

        guard response.target.caseInsensitiveCompare(adapter) == .orderedSame else {
            throw .other(.decoding(field: "target", value: response.target))
        }

        guard Self.calldata(response.data, carries: conditionId) else {
            throw .other(.decoding(field: "data", value: response.data))
        }

        return call
    }

    func mapRedeemRecord(_ response: PolymarketDTO.RedeemRecordResponse) -> PolymarketRedeemRecord {
        PolymarketRedeemRecord(
            transactionId: response.transactionId,
            state: response.state,
            transactionHash: response.transactionHash
        )
    }
}

// MARK: - Private implementation

private extension PolymarketMapper {
    static func calldata(_ data: String, carries conditionId: String) -> Bool {
        let word = conditionId.lowercased().removeHexPrefix()
        let payload = data.lowercased().removeHexPrefix()

        guard word.count == Constants.wordLength,
              payload.count > Constants.selectorLength,
              (payload.count - Constants.selectorLength) % Constants.wordLength == 0 else {
            return false
        }

        let arguments = Array(payload.dropFirst(Constants.selectorLength))

        return stride(from: 0, to: arguments.count, by: Constants.wordLength).contains { offset in
            String(arguments[offset ..< offset + Constants.wordLength]) == word
        }
    }

    enum Constants {
        static let selectorLength = 8
        static let wordLength = 64
    }
}
