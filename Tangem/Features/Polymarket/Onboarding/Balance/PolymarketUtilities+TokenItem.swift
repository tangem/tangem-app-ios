//
//  PolymarketUtilities+TokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket

extension PolymarketUtilities {
    static var collateralTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "Polymarket USD",
                symbol: "pUSD",
                contractAddress: PolymarketCollateral.contractAddress,
                decimalCount: PolymarketCollateral.decimalCount,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(blockchain, derivationPath: derivationPath)
        )
    }

    static let usdcContractAddress = "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"

    static var usdcTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "USDC",
                symbol: "USDC",
                contractAddress: usdcContractAddress,
                decimalCount: Constants.usdcDecimalCount,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(blockchain, derivationPath: derivationPath)
        )
    }
}

// MARK: - Bridge asset lookup

extension PolymarketUtilities {
    static func usdcOnPolygon(in assets: [PolymarketSupportedAsset]) -> PolymarketSupportedAsset? {
        guard let polygonChainId = blockchain.chainId.map(String.init) else {
            return nil
        }

        return assets.first { asset in
            asset.chainId == polygonChainId
                && asset.token.address.caseInsensitiveCompare(usdcContractAddress) == .orderedSame
        }
    }
}

// MARK: - Constants

private extension PolymarketUtilities {
    enum Constants {
        static let usdcDecimalCount = 6
    }
}
