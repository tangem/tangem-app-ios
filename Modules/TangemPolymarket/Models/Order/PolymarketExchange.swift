//
//  PolymarketExchange.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketExchange {
    public static let depositWalletSignatureType = 3

    public static let emptyWord = "0x" + String(repeating: "0", count: 64)

    static let domainName = "Polymarket CTF Exchange"
    static let domainVersion = "2"
    static let chainId = UInt64(PolymarketChain.polygonId)

    static func address(isNegRisk: Bool) -> String {
        isNegRisk ? PolymarketApprovalContracts.negRiskCtfExchange : PolymarketApprovalContracts.ctfExchange
    }
}
