//
//  KeyValuePanelView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct KeyValuePanelView: View {
    let config: KeyValuePanelConfig
    @State private var width: CGFloat = 0

    private var itemWidth: CGFloat {
        max(0, (width - Constants.interitemSpacing - Constants.backgroundHorizontalPadding * 2) / 2)
    }

    private var gridItems: [GridItem] {
        [GridItem(.adaptive(minimum: itemWidth), spacing: Constants.interitemSpacing, alignment: .topLeading)]
    }

    public init(config: KeyValuePanelConfig) {
        self.config = config
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let header = config.header {
                makeHeaderView(header)
            }

            LazyVGrid(columns: gridItems, alignment: .center, spacing: Constants.interitemSpacing) {
                ForEach(config.keyValues.indexed(), id: \.0) { _, pair in
                    KeyValuePairView(pair: pair)
                        .frame(minWidth: itemWidth, alignment: .leading)
                }
            }
            .readGeometry { value in
                width = value.frame.width
            }
        }
        .ifLet(config.backgroundColor) { view, color in
            view.roundedBackground(
                with: color,
                verticalPadding: Constants.backgroundVerticalPadding,
                horizontalPadding: Constants.backgroundHorizontalPadding,
                radius: 14
            )
        }
    }

    @ViewBuilder
    private func makeHeaderView(_ headerModel: KeyValuePanelConfig.Header) -> some View {
        if let actionConfig = headerModel.actionConfig {
            HStack(spacing: 0) {
                makeHeaderText(from: headerModel.title)

                Spacer()

                makeHeaderButton(from: actionConfig)
            }
        } else {
            makeHeaderText(from: headerModel.title)
        }
    }

    private func makeHeaderText(from string: String) -> some View {
        Text(string)
            .lineLimit(1)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    private func makeHeaderButton(from actionConfig: KeyValuePanelConfig.Header.ActionConfig) -> some View {
        Button(action: actionConfig.action) {
            HStack(spacing: 4) {
                if let imageType = actionConfig.image {
                    imageType.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.accent)
                }

                Text(actionConfig.buttonTitle)
                    .lineLimit(1)
                    .style(Fonts.Regular.footnote, color: Colors.Text.accent)
            }
        }
    }
}

private extension KeyValuePanelView {
    enum Constants {
        static let interitemSpacing: CGFloat = 12
        static let backgroundHorizontalPadding: CGFloat = 14
        static let backgroundVerticalPadding: CGFloat = 14
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.gray
        KeyValuePanelView(
            config: KeyValuePanelConfig(
                header: KeyValuePanelConfig.Header(
                    title: "Header",
                    actionConfig: .init(buttonTitle: "see all", image: Assets.arrowRightUp, action: {})
                ),
                keyValues: (0 ... 5).map {
                    KeyValuePairViewData(
                        key: KeyValuePairViewData.Key(text: "Title-\($0)", action: nil),
                        value: KeyValuePairViewData.Value(text: "Value-\($0)", icon: nil)
                    )
                },
                backgroundColor: Colors.Background.action
            )
        )
        .padding(.horizontal, 16)
    }
}
#endif
