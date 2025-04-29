//
//  NFTDetailsHeaderVew.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils
import TangemUI

struct NFTDetailsHeaderView: View {
    let state: NFTDetailsHeaderState

    var body: some View {
        content
            .roundedBackground(with: Constants.backgroundColor, padding: 14, radius: 14)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .full(let priceWithDescriptionState, let rarity):
            makeFullState(
                priceWithDescriptionState: priceWithDescriptionState,
                rarity: rarity
            )

        case .priceWithDescription(let priceWithDescriptionState):
            makePriceWithDescriptionBlock(state: priceWithDescriptionState)

        case .rarity(let rarity):
            makeRarityKeyValueView(keyValues: rarity)
        }
    }

    private func makeFullState(
        priceWithDescriptionState: NFTDetailsHeaderState.PriceWithDescriptionState,
        rarity: [KeyValuePairViewData]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            makePriceWithDescriptionBlock(state: priceWithDescriptionState)
                .padding(.bottom, rarity.isNotEmpty ? 12 : 0)

            if rarity.isNotEmpty {
                Separator(height: .exact(1), color: Colors.Stroke.primary, axis: .horizontal)
                    .padding(.bottom, 14)

                makeRarityKeyValueView(keyValues: rarity)
            }
        }
    }

    @ViewBuilder
    private func makePriceWithDescriptionBlock(state: NFTDetailsHeaderState.PriceWithDescriptionState) -> some View {
        switch state {
        case .price(let price):
            makePrices(model: price)

        case .description(let config):
            NFTDescriptionView(
                text: config.text,
                backgroundColor: Constants.backgroundColor,
                readMoreAction: config.readMoreAction
            )

        case .priceWithDescription(let price, let descriptionConfig):
            VStack(alignment: .leading, spacing: 14) {
                makePrices(model: price)

                NFTDescriptionView(
                    text: descriptionConfig.text,
                    backgroundColor: Constants.backgroundColor,
                    readMoreAction: descriptionConfig.readMoreAction
                )
            }
        }
    }

    private func makePrices(model: NFTDetailsHeaderState.Price) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Last sale price") // [REDACTED_TODO_COMMENT]
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 8)

            Text(model.raw)
                .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                .padding(.bottom, 4)

            Text(model.quote)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private func makeRarityKeyValueView(keyValues: [KeyValuePairViewData]) -> some View {
        KeyValuePanelView(
            config: KeyValuePanelConfig(
                header: nil,
                keyValues: keyValues,
                backgroundColor: nil
            )
        )
    }
}

private extension NFTDetailsHeaderView {
    enum Constants {
        static let backgroundColor = Colors.Background.action
    }
}

#if DEBUG
#Preview("Maximum state") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .full(
                .priceWithDescription(
                    .init(raw: "0.0015 ETH", quote: "34,5 $"),
                    .init(
                        text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In nunc velit, aliquet vitae facilisis eu, malesuada vitae dui. Cras eget.",
                        readMoreAction: {}
                    )
                ),
                (0 ... 1).map {
                    KeyValuePairViewData(
                        key: KeyValuePairViewData.Key(text: "Title-\($0)", action: nil),
                        value: KeyValuePairViewData.Value(text: "Value-\($0)", icon: nil)
                    )
                }
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Full state without rarity") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .full(
                .priceWithDescription(
                    .init(raw: "0.0015 ETH", quote: "34,5 $"),
                    .init(
                        text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In nunc velit, aliquet vitae facilisis eu, malesuada vitae dui. Cras eget.",
                        readMoreAction: {}
                    )
                ),
                []
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Only Price") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .priceWithDescription(
                .price(.init(raw: "0.0015 ETH", quote: "34,5 $"))
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Only description") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .priceWithDescription(
                .description(
                    .init(
                        text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In nunc velit, aliquet vitae facilisis eu, malesuada vitae dui. Cras eget.",
                        readMoreAction: {}
                    )
                )
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Only rarity") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .rarity(
                (0 ... 1).map {
                    KeyValuePairViewData(
                        key: KeyValuePairViewData.Key(text: "Title-\($0)", action: nil),
                        value: KeyValuePairViewData.Value(text: "Value-\($0)", icon: nil)
                    )
                }
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Price with description") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .priceWithDescription(
                .priceWithDescription(
                    .init(raw: "0.0015 ETH", quote: "34,5 $"),
                    .init(
                        text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In nunc velit, aliquet vitae facilisis eu, malesuada vitae dui. Cras eget.",
                        readMoreAction: {}
                    )
                )
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Price and rarity") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .full(
                .price(.init(raw: "0.0015 ETH", quote: "34,5 $")),
                (0 ... 1).map {
                    KeyValuePairViewData(
                        key: KeyValuePairViewData.Key(text: "Title-\($0)", action: nil),
                        value: KeyValuePairViewData.Value(text: "Value-\($0)", icon: nil)
                    )
                }
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Description and rarity") {
    ZStack {
        Color.gray
        NFTDetailsHeaderView(
            state: .full(
                .description(
                    .init(
                        text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In nunc velit, aliquet vitae facilisis eu, malesuada vitae dui. Cras eget.",
                        readMoreAction: {}
                    )
                ),
                (0 ... 1).map {
                    KeyValuePairViewData(
                        key: KeyValuePairViewData.Key(text: "Title-\($0)", action: nil),
                        value: KeyValuePairViewData.Value(text: "Value-\($0)", icon: nil)
                    )
                }
            )
        )
        .padding(.horizontal, 16)
    }
}

#endif
