//
//  FeeSelectorMockUIUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct FeeSelectorMockUIUtils {}

extension FeeSelectorMockUIUtils {
    static func mockFeeSelectorFee(feeOption: FeeOption = .market) -> TokenFee {
        return TokenFee(
            option: feeOption,
            tokenItem: FeeSelectorMockUIUtils.mockTokenItem,
            value: .success(.init(Amount(with: FeeSelectorMockUIUtils.mockTokenItem.token!, value: Decimal(Int.random(in: 10 ... 300)))))
        )
    }

    static func mockBSDKFee() -> BSDKFee {
        BSDKFee(
            .zeroToken(token: FeeSelectorMockUIUtils.mockToken),
            parameters: EthereumEIP1559FeeParameters(gasLimit: 100000, baseFee: 10000, priorityFee: 10000)
        )
    }

    static var mockSelectorFeess: [TokenFee] {
        if Bool.random() {
            return [mockFeeSelectorFee(feeOption: .market)]
        }

        let feeOptions: [FeeOption] = [.slow, .market, .fast, .custom].shuffled()
        return feeOptions.map(mockFeeSelectorFee)
    }
}

extension FeeSelectorMockUIUtils {
    static var blockchain: Blockchain {
        .ethereum(testnet: false)
    }

    static var mockToken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: "tether"
        )
    }

    static var mockTokenItem: TokenItem {
        .token(mockToken, .init(blockchain, derivationPath: nil))
    }

    /// Returns either a single mock token or ten different mock tokens, chosen randomly
    static var mockTokens: [TokenItem] {
        let candidates: [(name: String, symbol: String, id: String)] = [
            ("Tether", "USDT", "tether"),
            ("USD Coin", "USDC", "usd-coin"),
            ("Dai", "DAI", "dai"),
            ("Wrapped Ether", "WETH", "weth"),
            ("Shiba Inu", "SHIB", "shiba-inu"),
            ("Chainlink", "LINK", "chainlink"),
            ("Uniswap", "UNI", "uniswap"),
            ("Aave", "AAVE", "aave"),
            ("Maker", "MKR", "maker"),
            ("Polygon", "MATIC", "matic-network"),
        ]

        return candidates.map { item in
            let token = Token(
                name: item.name,
                symbol: item.symbol,
                contractAddress: "0x" + String(item.id.hashValue.magnitude, radix: 16),
                decimalCount: 18,
                id: item.id
            )

            return TokenItem.token(token, .init(blockchain, derivationPath: nil))
        }
    }
}
