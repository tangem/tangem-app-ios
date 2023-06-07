//
//  OrganizeTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class OrganizeTokensViewModel: ObservableObject {
    let headerViewModel: OrganizeTokensHeaderViewModel

    @Published
    var sections: [OrganizeTokensListSectionViewModel]

    private unowned let coordinator: OrganizeTokensRoutable

    init(
        coordinator: OrganizeTokensRoutable
    ) {
        self.coordinator = coordinator
        headerViewModel = OrganizeTokensHeaderViewModel()

        // [REDACTED_TODO_COMMENT]
        sections = [
            .init(
                title: "Bitcoin network",
                isDraggable: true,
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
                title: "Ethereum network",
                isDraggable: false,
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
