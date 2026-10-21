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
    func mapRedeemCalls(
        _ response: PolymarketDTO.RedeemCallResponse,
        request: PolymarketRedeemCallRequest
    ) throws(PolymarketRedeemError) -> [PolymarketRelayedBatch.Call] {
        let version = PolymarketMarketVersion(apiValue: response.version)

        guard let expected = request.version, expected.isSupported, version == expected else {
            throw .other(.decoding(field: "version", value: response.version ?? ""))
        }

        guard Self.allowedCallCount(for: version).contains(response.calls.count) else {
            throw .other(.decoding(field: "calls", value: String(response.calls.count)))
        }

        let calls = try response.calls.map { dto throws(PolymarketRedeemError) in
            let call = PolymarketRelayedBatch.Call(target: dto.target, data: dto.data)

            guard dto.value == call.value else {
                throw .other(.decoding(field: "value", value: dto.value))
            }

            return call
        }

        switch version {
        case .v1:
            try Self.validateV1(calls, request: request)
        case .v2:
            try Self.validateV2(calls, request: request)
        case .unknown:
            throw .other(.decoding(field: "version", value: response.version ?? ""))
        }

        return calls
    }

    func mapRedeemRecord(_ response: PolymarketDTO.RedeemRecordResponse) -> PolymarketRedeemRecord {
        PolymarketRedeemRecord(
            transactionId: response.transactionId,
            state: response.state,
            transactionHash: response.transactionHash
        )
    }
}

// MARK: - V1

private extension PolymarketMapper {
    static func validateV1(
        _ calls: [PolymarketRelayedBatch.Call],
        request: PolymarketRedeemCallRequest
    ) throws(PolymarketRedeemError) {
        let adapter = request.isNegRisk
            ? PolymarketApprovalContracts.negRiskCtfCollateralAdapter
            : PolymarketApprovalContracts.ctfCollateralAdapter

        for call in calls {
            guard call.target.caseInsensitiveCompare(adapter) == .orderedSame else {
                throw .other(.decoding(field: "target", value: call.target))
            }

            guard calldata(call.data, carries: request.conditionId) else {
                throw .other(.decoding(field: "data", value: call.data))
            }
        }
    }

    static func calldata(_ data: String, carries conditionId: String) -> Bool {
        let word = conditionId.lowercased().removeHexPrefix()

        guard word.count == Constants.wordLength, let arguments = arguments(of: data) else {
            return false
        }

        return arguments.words.contains(word)
    }
}

// MARK: - V2

private extension PolymarketMapper {
    static func validateV2(
        _ calls: [PolymarketRelayedBatch.Call],
        request: PolymarketRedeemCallRequest
    ) throws(PolymarketRedeemError) {
        guard let conditionWord = v2ConditionWord(assetId: request.assetId) else {
            throw .other(.decoding(field: "assetId", value: request.assetId))
        }

        var outcomeIndices: Set<String> = []

        for call in calls {
            guard call.target.caseInsensitiveCompare(PolymarketApprovalContracts.routerV3) == .orderedSame else {
                throw .other(.decoding(field: "target", value: call.target))
            }

            guard
                let arguments = arguments(of: call.data),
                arguments.selector == Constants.routerRedeemSelector,
                arguments.words.count == Constants.routerRedeemWordCount
            else {
                throw .other(.decoding(field: "data", value: call.data))
            }

            let condition = arguments.words[0]
            let outcomeIndex = arguments.words[1]
            let amount = arguments.words[2]

            guard
                condition == conditionWord,
                Constants.outcomeIndexWords.contains(outcomeIndex),
                outcomeIndices.insert(outcomeIndex).inserted,
                amount != Constants.zeroWord
            else {
                throw .other(.decoding(field: "data", value: call.data))
            }
        }
    }

    static func v2ConditionWord(assetId: String) -> String? {
        guard let word = try? PolymarketOrderSigning.word(decimalString: assetId) else {
            return nil
        }

        var conditionBytes = word
        conditionBytes[conditionBytes.index(before: conditionBytes.endIndex)] = 0

        return conditionBytes.map { String(format: "%02x", $0) }.joined()
    }

    static func allowedCallCount(for version: PolymarketMarketVersion) -> ClosedRange<Int> {
        switch version {
        case .v1: 1 ... 1
        case .v2: 1 ... 2
        case .unknown: 0 ... 0
        }
    }
}

// MARK: - Calldata

private extension PolymarketMapper {
    struct Arguments {
        let selector: String
        let words: [String]
    }

    static func arguments(of data: String) -> Arguments? {
        let payload = data.lowercased().removeHexPrefix()

        guard
            payload.count > Constants.selectorLength,
            (payload.count - Constants.selectorLength) % Constants.wordLength == 0,
            payload.allSatisfy(\.isHexDigit)
        else {
            return nil
        }

        let arguments = Array(payload.dropFirst(Constants.selectorLength))

        let words = stride(from: 0, to: arguments.count, by: Constants.wordLength).map { offset in
            String(arguments[offset ..< offset + Constants.wordLength])
        }

        return Arguments(selector: String(payload.prefix(Constants.selectorLength)), words: words)
    }

    enum Constants {
        static let selectorLength = 8
        static let wordLength = 64

        static let routerRedeemSelector = "d217a3cc"
        static let routerRedeemWordCount = 3

        static let zeroWord = String(repeating: "0", count: wordLength)
        static let outcomeIndexWords: Set<String> = [
            zeroWord,
            String(repeating: "0", count: wordLength - 1) + "1",
        ]
    }
}
