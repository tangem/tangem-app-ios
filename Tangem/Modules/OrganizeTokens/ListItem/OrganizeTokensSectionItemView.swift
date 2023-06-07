//
//  OrganizeTokensSectionItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// For SwiftUI previews only
#if targetEnvironment(simulator)
import struct BlockchainSdk.Token
#endif

struct OrganizeTokensSectionItemView: View {
    let viewModel: OrganizeTokensListItemViewModel

    var body: some View {
        HStack(spacing: 12.0) {
            TokenIconView(
                viewModel: viewModel.tokenIconViewModel,
                size: .init(bothDimensions: 36.0)
            )
            .layoutPriority(1.0)

            VStack(alignment: .leading, spacing: 2.0) {
                Group {
                    Text(viewModel.tokenName)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(viewModel.tokenTotalSum)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
                .lineLimit(1)
            }

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
                        tokenName: "Bitcoin",
                        tokenTotalSum: "222.00 $",
                        isDraggable: true,
                        tokenIconViewModel: .init(
                            tokenItem: .blockchain(.bitcoin(testnet: false))
                        )
                    )
                )

                OrganizeTokensSectionItemView(
                    viewModel: .init(
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
                    )
                )

                OrganizeTokensSectionItemView(
                    viewModel: .init(
                        tokenName: "ExtraLongTokenName_ExtraLongTokenName_ExtraLongTokenName",
                        tokenTotalSum: "22222222222222222222222222222222222222222222222222.00 $",
                        isDraggable: true,
                        tokenIconViewModel: .init(
                            tokenItem: .blockchain(.ethereumPoW(testnet: false))
                        )
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
