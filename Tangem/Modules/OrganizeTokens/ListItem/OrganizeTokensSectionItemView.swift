//
//  OrganizeTokensSectionItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensSectionItemView: View {
    let viewModel: OrganizeTokensListItemViewModel

    var body: some View {
        HStack(spacing: 12.0) {
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                blockchainIconName: viewModel.blockchainIconName,
                networkUnreachable: viewModel.networkUnreachable
            )

            TokenItemViewMiddleComponent(
                name: viewModel.name,
                balance: viewModel.balance,
                hasPendingTransactions: viewModel.hasPendingTransactions,
                networkUnreachable: viewModel.networkUnreachable
            )

            Spacer(minLength: 0.0)

            if viewModel.isDraggable {
                Assets.OrganizeTokens.itemDragAndDropIcon
                    .image
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: .init(bothDimensions: 20.0))
                    .foregroundColor(Colors.Icon.informative)
                    .layoutPriority(1.0)
            }
        }
        .padding(.horizontal, 14.0)
        .frame(height: 68.0)
    }
}

// MARK: - Previews

struct OrganizeTokensSectionItemView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                OrganizeTokensSectionItemView(
                    viewModel: .init(
                        tokenIcon: TokenIconInfoBuilder().build(
                            for: .coin,
                            in: .bitcoin(testnet: false)
                        ),
                        balance: .loading,
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    )
                )

                OrganizeTokensSectionItemView(
                    viewModel: .init(
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
                    )
                )

                OrganizeTokensSectionItemView(
                    viewModel: .init(
                        tokenIcon: .init(
                            name: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                            blockchainIconName: nil,
                            imageURL: nil
                        ),
                        balance: .loaded(text: "22222222222222222222222222222222222222222222.00 $"),
                        isDraggable: true,
                        networkUnreachable: false,
                        hasPendingTransactions: false
                    )
                )
            }
            .background(Colors.Background.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary)
    }
}
