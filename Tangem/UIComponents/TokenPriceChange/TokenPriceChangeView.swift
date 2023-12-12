//
//  TokenPriceChangeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenPriceChangeView: View {
    let state: State

    private let loaderSize = CGSize(width: 40, height: 12)

    var body: some View {
        switch state {
        case .initialized:
            styledDashText
                .opacity(0.01)
        case .noData:
            styledDashText
        case .empty:
            Text("")
        case .loading:
            styledText("----")
                .opacity(0.01)
                .skeletonable(isShown: true)
        case .loaded(let signType, let text):
            HStack(spacing: 4) {
                if let icon = signType.imageType?.image {
                    icon
                        .renderingMode(.template)
                        .foregroundColor(signType.textColor)
                }

                styledText(text, textColor: signType.textColor)
                    .skeletonable(isShown: false)
            }
        }
    }

    private var styledDashText: some View {
        styledText("–")
    }

    @ViewBuilder
    private func styledText(_ text: String, textColor: Color = Colors.Text.tertiary) -> some View {
        Text(text)
            .style(Fonts.Regular.caption1, color: textColor)
            .lineLimit(1)
    }
}

extension TokenPriceChangeView {
    enum State: Hashable {
        case initialized
        case noData
        case empty
        case loading
        case loaded(signType: ChangeSignType, text: String)
    }
}
