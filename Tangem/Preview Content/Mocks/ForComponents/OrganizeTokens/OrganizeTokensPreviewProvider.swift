//
//  OrganizeTokensPreviewProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensPreviewProvider {
    func singleSmallHeaderlessSection() -> [OrganizeTokensListSectionViewModel] {
        return [
            .init(
                style: .invisible,
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func singleSmallSection() -> [OrganizeTokensListSectionViewModel] {
        return [
            .init(
                style: .draggable(title: "Bitcoin Network"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func singleMediumSection() -> [OrganizeTokensListSectionViewModel] {
        return [
            .init(
                style: .draggable(title: "Bitcoin network"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(value: .tetherMock),
                            in: .ethereumClassic(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: true,
                        isDraggable: false
                    ),
                ]
            ),
        ]
    }

    func singleLargeSection() -> [OrganizeTokensListSectionViewModel] {
        return [
            .init(
                style: .invisible,
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .bitcoin(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .arbitrum(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .litecoin),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .stellar(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ethereum(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ), .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ethereumPoW(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ethereumClassic(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .bitcoinCash(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .binance(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .cardano),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .bsc(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .dogecoin),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ), .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .polygon(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ), .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .avalanche(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .solana(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .fantom(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .polkadot(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .azero(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .tron(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .dash(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .optimism(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ), .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ton(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ), .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .kava(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ), .init(
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .cosmos(testnet: false)),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func multipleSections() -> [OrganizeTokensListSectionViewModel] {
        return [
            .init(
                style: .draggable(title: "Section #1"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                style: .draggable(title: "Section #2"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                style: .draggable(title: "Section #3"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                style: .draggable(title: "Section #4"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                style: .draggable(title: "Section #5"),
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(
                                value: .init(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                )
                            ),
                            in: .dash(testnet: false)
                        ),
                        balance: .noData,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }
}
