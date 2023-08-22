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
                id: UUID(),
                style: .invisible,
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
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
                id: UUID(),
                style: .draggable(title: "Bitcoin Network"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
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
                id: UUID(),
                style: .draggable(title: "Bitcoin network"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
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
                        hasDerivation: false,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: true,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(value: .tetherMock),
                            in: .ethereumClassic(testnet: false)
                        ),
                        balance: .noData,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }

    func singleLargeSection() -> [OrganizeTokensListSectionViewModel] {
        return [
            .init(
                id: UUID(),
                style: .invisible,
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .bitcoin(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .arbitrum(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .litecoin),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .stellar(curve: .ed25519_slip0010, testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ethereum(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ethereumPoW(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ethereumClassic(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .bitcoinCash(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .binance(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .cardano(extended: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .bsc(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .dogecoin),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .polygon(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .avalanche(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .solana(curve: .ed25519_slip0010, testnet: false)),
                        balance: .loading,
                        hasDerivation: false,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .fantom(testnet: false)),
                        balance: .loading,
                        hasDerivation: false,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .polkadot(curve: .ed25519_slip0010, testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .azero(curve: .ed25519_slip0010, testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .tron(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .dash(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: true,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .optimism(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: true,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .ton(curve: .ed25519_slip0010, testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .kava(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(for: .coin, in: .cosmos(testnet: false)),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
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
                id: UUID(),
                style: .draggable(title: "Section #1"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
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
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                id: UUID(),
                style: .draggable(title: "Section #2"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
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
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                id: UUID(),
                style: .draggable(title: "Section #3"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
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
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                id: UUID(),
                style: .draggable(title: "Section #4"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
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
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),

            .init(
                id: UUID(),
                style: .draggable(title: "Section #5"),
                items: [
                    .init(
                        id: .random(),
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: true,
                        isDraggable: true
                    ),
                    .init(
                        id: .random(),
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
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: false
                    ),
                    .init(
                        id: .random(),
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        hasDerivation: true,
                        isTestnet: false,
                        isNetworkUnreachable: false,
                        isDraggable: true
                    ),
                ]
            ),
        ]
    }
}

// MARK: - Convenience extensions

private extension OrganizeTokensListItemViewModel.Identifier {
    static func random() -> Self {
        return .init(
            walletModelId: .random(in: 0 ..< Int.max),
            inGroupedSection: .random()
        )
    }
}
