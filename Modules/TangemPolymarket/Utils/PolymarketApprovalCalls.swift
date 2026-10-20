//
//  PolymarketApprovalCalls.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketApprovalCalls {
    public static func make() -> [PolymarketRelayedBatch.Call] {
        [
            approve(spender: PolymarketApprovalContracts.conditionalTokens),
            approve(spender: PolymarketApprovalContracts.ctfExchange),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.ctfExchange),
            approve(spender: PolymarketApprovalContracts.negRiskCtfExchange),
            approve(spender: PolymarketApprovalContracts.negRiskAdapter),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.negRiskCtfExchange),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.negRiskAdapter),
            approve(spender: PolymarketApprovalContracts.ctfCollateralAdapter),
            approve(spender: PolymarketApprovalContracts.negRiskCtfCollateralAdapter),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.ctfCollateralAdapter),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.negRiskCtfCollateralAdapter),
            approve(spender: PolymarketApprovalContracts.exchangeV3),
            approve(spender: PolymarketApprovalContracts.routerV3),
            setApprovalForAll(token: PolymarketApprovalContracts.positionManager, operator: PolymarketApprovalContracts.exchangeV3),
            setApprovalForAll(token: PolymarketApprovalContracts.positionManager, operator: PolymarketApprovalContracts.routerV3),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.binaryModule),
            setApprovalForAll(token: PolymarketApprovalContracts.conditionalTokens, operator: PolymarketApprovalContracts.negRiskModule),
        ]
    }
}

// MARK: - Private implementation

private extension PolymarketApprovalCalls {
    static func approve(spender: String) -> PolymarketRelayedBatch.Call {
        PolymarketRelayedBatch.Call(
            target: PolymarketCollateral.contractAddress,
            data: Constants.approveSelector + leftPaddedWord(spender) + Constants.maxUint256
        )
    }

    static func setApprovalForAll(token: String, operator operatorAddress: String) -> PolymarketRelayedBatch.Call {
        PolymarketRelayedBatch.Call(
            target: token,
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
