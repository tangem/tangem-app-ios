//
//  Token+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension Token {
    static let usdcToken: Self = .init(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85",
        decimalCount: 6
    )

    static let usdcToken_18Decimals: Self = .init(
        name: "USD Coin",
        symbol: "USDC",
        contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        decimalCount: 18
    )

    static let nftERC721Token: Self = .init(
        name: "Pudgy Penguin",
        symbol: "ETH",
        contractAddress: "0xbd3531da5cf5857e7cfaa92426877b022e612cf8",
        decimalCount: 6,
        metadata: .init(kind: .nonFungible(assetIdentifier: "3034", contractType: .erc721))
    )

    static let nftERC1155Token: Self = .init(
        name: "Sunflower Land Inventory #251",
        symbol: "MATIC",
        contractAddress: "0x22d5f9B75c524Fec1D6619787e582644CD4D7422",
        decimalCount: 6,
        metadata: .init(kind: .nonFungible(assetIdentifier: "251", contractType: .erc1155))
    )

    static let nftUnknownStandardToken: Self = .init(
        name: "Unknown",
        symbol: "Blank",
        contractAddress: "",
        decimalCount: 6,
        metadata: .init(kind: .nonFungible(assetIdentifier: "251", contractType: .unspecified))
    )
}
