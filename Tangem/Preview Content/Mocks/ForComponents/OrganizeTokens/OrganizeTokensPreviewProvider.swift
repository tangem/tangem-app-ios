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
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
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
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
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
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
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
                        isDraggable: false,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .token(value: .tetherMock),
                            in: .ethereumClassic(testnet: false)
                        ),
                        balance: .noData,
                        isDraggable: false,
                        networkUnreachable: true,
                        hasPendingTransactions: true
                    ),
                ]
            ),
        ]
    }

    func multipleSections() -> [OrganizeTokensListSectionViewModel] {
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
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
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
                        isDraggable: false,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                ]
            ),

            .init(
                style: .invisible,
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isDraggable: true,
                        networkUnreachable: true,
                        hasPendingTransactions: false
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
                        isDraggable: false,
                        networkUnreachable: false,
                        hasPendingTransactions: true
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                ]
            ),

            .init(
                style: .invisible,
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isDraggable: true,
                        networkUnreachable: true,
                        hasPendingTransactions: false
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
                        isDraggable: false,
                        networkUnreachable: false,
                        hasPendingTransactions: true
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                ]
            ),

            .init(
                style: .invisible,
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isDraggable: true,
                        networkUnreachable: true,
                        hasPendingTransactions: false
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
                        isDraggable: false,
                        networkUnreachable: false,
                        hasPendingTransactions: true
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                ]
            ),

            .init(
                style: .invisible,
                items: [
                    .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .ethereum(testnet: false)
                        ),
                        balance: .loading,
                        isDraggable: true,
                        networkUnreachable: true,
                        hasPendingTransactions: false
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
                        isDraggable: false,
                        networkUnreachable: false,
                        hasPendingTransactions: true
                    ),
                    .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    ),
                ]
            ),
        ]
    }
}
