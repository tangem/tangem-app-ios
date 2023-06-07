//
//  OrganizeTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

// For SwiftUI previews only
#if targetEnvironment(simulator)
import struct BlockchainSdk.Token
#endif

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
                        tokenName: "Bitcoin",
                        tokenTotalSum: "222.00 $",
                        isDraggable: true,
                        tokenIconViewModel: .init(
                            tokenItem: .blockchain(.bitcoin(testnet: false))
                        )
                    ),

                    .init(
                        tokenName: "DAI",
                        tokenTotalSum: "222.00 $",
                        isDraggable: false,
                        tokenIconViewModel: .init(
                            tokenItem: .token(
                                Token(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                ),
                                .cosmos(testnet: false)
                            )
                        )
                    ),

                    .init(
                        tokenName: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                        tokenTotalSum: "22222222222222222222222222222222222222222222222222.00 $",
                        isDraggable: true,
                        tokenIconViewModel: .init(
                            tokenItem: .blockchain(.ethereumPoW(testnet: false))
                        )
                    ),
                ]
            ),

            .init(
                title: "Ethereum network",
                isDraggable: false,
                items: [
                    .init(
                        tokenName: "Bitcoin",
                        tokenTotalSum: "222.00 $",
                        isDraggable: true,
                        tokenIconViewModel: .init(
                            tokenItem: .blockchain(.bitcoin(testnet: false))
                        )
                    ),

                    .init(
                        tokenName: "DAI",
                        tokenTotalSum: "222.00 $",
                        isDraggable: false,
                        tokenIconViewModel: .init(
                            tokenItem: .token(
                                Token(
                                    name: "DAI",
                                    symbol: "DAI",
                                    contractAddress: "0xdwekdn32jfne",
                                    decimalCount: 18
                                ),
                                .cosmos(testnet: false)
                            )
                        )
                    ),

                    .init(
                        tokenName: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                        tokenTotalSum: "22222222222222222222222222222222222222222222222222.00 $",
                        isDraggable: true,
                        tokenIconViewModel: .init(
                            tokenItem: .blockchain(.ethereumPoW(testnet: false))
                        )
                    ),
                ]
            ),
        ]
    }
}
