//
//  PolymarketApprovalCalls.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketApprovalCalls {
    public static func make() -> [PolymarketApprovalsBatch.Call] {
        [
            approve(spender: PolymarketApprovalContracts.conditionalTokens),
            approve(spender: PolymarketApprovalContracts.ctfExchange),
            setApprovalForAll(operator: PolymarketApprovalContracts.ctfExchange),
            approve(spender: PolymarketApprovalContracts.negRiskCtfExchange),
            approve(spender: PolymarketApprovalContracts.negRiskAdapter),
            setApprovalForAll(operator: PolymarketApprovalContracts.negRiskCtfExchange),
            setApprovalForAll(operator: PolymarketApprovalContracts.negRiskAdapter),
            approve(spender: PolymarketApprovalContracts.ctfCollateralAdapter),
            approve(spender: PolymarketApprovalContracts.negRiskCtfCollateralAdapter),
            setApprovalForAll(operator: PolymarketApprovalContracts.ctfCollateralAdapter),
            setApprovalForAll(operator: PolymarketApprovalContracts.negRiskCtfCollateralAdapter),
            approve(spender: PolymarketApprovalContracts.exchangeV3),
            approve(spender: PolymarketApprovalContracts.routerV3),
        ]
    }
}

// MARK: - Private implementation

private extension PolymarketApprovalCalls {
    static func approve(spender: String) -> PolymarketApprovalsBatch.Call {
        PolymarketApprovalsBatch.Call(
            target: PolymarketCollateral.contractAddress,
            data: Constants.approveSelector + leftPaddedWord(spender) + Constants.maxUint256
        )
    }

    static func setApprovalForAll(operator operatorAddress: String) -> PolymarketApprovalsBatch.Call {
        PolymarketApprovalsBatch.Call(
            target: PolymarketApprovalContracts.conditionalTokens,
            data: Constants.setApprovalForAllSelector + leftPaddedWord(operatorAddress) + Constants.boolTrue
        )
    }

    static func leftPaddedWord(_ address: String) -> String {
        let digits = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
        return String(repeating: "0", count: max(0, Constants.wordLength - digits.count)) + digits.lowercased()
    }

    enum Constants {
        static let approveSelector = "0x095ea7b3"
        static let setApprovalForAllSelector = "0xa22cb465"
        static let maxUint256 = String(repeating: "f", count: 64)
        static let boolTrue = String(repeating: "0", count: 63) + "1"
        static let wordLength = 64
    }
}
