//
//  TransferInputTokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct TransferInputTokenItem: Identifiable, Equatable {
    let id: String
    let tokenIconInfo: TokenIconInfo
    let symbol: String
    let networkName: String
    let balance: Decimal
    let balanceText: String
    let chainId: Int
    let contractAddress: String
    let isOfframpAvailable: Bool
}

// MARK: - Previews

#if DEBUG
extension TransferInputTokenItem {
    static let previewList: [TransferInputTokenItem] = [
        makePreview(symbol: "USDC", network: "Polygon", chainId: 137, balance: 2325.55, isAvailable: true),
        makePreview(symbol: "USDC", network: "Base", chainId: 8453, balance: 12325.55, isAvailable: true),
        makePreview(symbol: "USDC", network: "Arbitrum", chainId: 42161, balance: 2325.55, isAvailable: true),
        makePreview(symbol: "USDC", network: "BNB", chainId: 56, balance: 120, isAvailable: false),
        makePreview(symbol: "USDT", network: "Polygon", chainId: 137, balance: 340, isAvailable: false),
        makePreview(symbol: "USDT", network: "Base", chainId: 8453, balance: 88, isAvailable: false),
    ]

    private static func makePreview(
        symbol: String,
        network: String,
        chainId: Int,
        balance: Decimal,
        isAvailable: Bool
    ) -> TransferInputTokenItem {
        TransferInputTokenItem(
            id: "\(chainId)-\(symbol.lowercased())",
            tokenIconInfo: .remote(name: symbol, imageURL: nil),
            symbol: symbol,
            networkName: network,
            balance: balance,
            balanceText: TangemPayOfframpAmountFormatter.formatBalance(balance),
            chainId: chainId,
            contractAddress: "0x\(symbol.lowercased())",
            isOfframpAvailable: isAvailable
        )
    }
}
#endif
