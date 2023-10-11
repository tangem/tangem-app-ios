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
        case .loading:
            ZStack {
                styledDashText
                    .opacity(0.01)
                SkeletonView()
                    .frame(size: loaderSize)
                    .cornerRadiusContinuous(3)
            }
        case .loaded(let signType, let text):
            HStack(spacing: 4) {
                if let icon = signType.imageType?.image {
                    icon
                        .renderingMode(.template)
                        .foregroundColor(signType.textColor)
                }

                styledText(text, textColor: signType.textColor)
            }
        }
    }

    private var styledDashText: some View {
        styledText("–")
    }

    @ViewBuilder
    private func styledText(_ text: String, textColor: Color = Colors.Text.tertiary) -> some View {
        Text(text)
            .style(Fonts.Regular.footnote, color: textColor)
            .lineLimit(1)
    }
}

extension TokenPriceChangeView {
    enum State: Hashable {
        case initialized
        case noData
        case loading
        case loaded(signType: ChangeSignType, text: String)
    }
}
