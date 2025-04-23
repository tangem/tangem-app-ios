//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct KeyValuePairView: View {
    let pair: KeyValuePairViewData

    init(pair: KeyValuePairViewData) {
        self.pair = pair
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            title
            subtitle
        }
    }

    // MARK: - Title

    @ViewBuilder
    private var title: some View {
        if let action = pair.key.action {
            Button(action: action) {
                HStack(spacing: 4) {
                    makeTitleText(from: pair.key.text)

                    Assets.infoCircle16.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.informative)
                }
            }
        } else {
            makeTitleText(from: pair.key.text)
        }
    }

    private func makeTitleText(from string: String) -> some View {
        Text(string)
            .lineLimit(1)
            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
    }

    // MARK: - Subtitle

    private var subtitle: some View {
        HStack(spacing: 4) {
            Text(pair.value.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

            if let imageType = pair.value.icon {
                imageType.image
            }
        }
    }
}

#if DEBUG
#Preview("No icon, no action") {
    KeyValuePairView(
        pair: KeyValuePairViewData(
            key: KeyValuePairViewData.Key(text: "Text", action: nil),
            value: KeyValuePairViewData.Value(text: "Text", icon: nil)
        )
    )
}

#Preview("With icon, with action") {
    KeyValuePairView(
        pair: KeyValuePairViewData(
            key: KeyValuePairViewData.Key(text: "Text", action: {}),
            value: KeyValuePairViewData.Value(text: "Text", icon: Assets.approve)
        )
    )
}
#endif
