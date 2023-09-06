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
            Text(" ")
                .frame(size: loaderSize)
        case .noData:
            Text("–")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .frame(minHeight: loaderSize.height)
        case .loading:
            SkeletonView()
                .frame(size: loaderSize)
                .cornerRadiusContinuous(3)
                .padding(.top, 6)
        case .loaded(let signType, let text):
            HStack(spacing: 4) {
                if let icon = signType.imageType?.image {
                    icon
                        .renderingMode(.template)
                }

                Text(text)
                    .lineLimit(1)
            }
            .style(Fonts.Regular.footnote, color: signType.textColor)
            .frame(minHeight: loaderSize.height)
        }
    }
}

extension TokenPriceChangeView {
    enum State: Hashable {
        case initialized
        case noData
        case loading
        case loaded(signType: ChangeSignType, text: String)
    }

    enum ChangeSignType: Int, Hashable {
        case positive
        case negative
        case same

        var imageType: ImageType? {
            switch self {
            case .positive:
                return Assets.quotePositive
            case .negative:
                return Assets.quoteNegative
            case .same:
                return nil
            }
        }

        var textColor: Color {
            switch self {
            case .positive:
                return Colors.Text.accent
            case .negative:
                return Colors.Text.warning
            case .same:
                return Colors.Text.tertiary
            }
        }
    }
}
