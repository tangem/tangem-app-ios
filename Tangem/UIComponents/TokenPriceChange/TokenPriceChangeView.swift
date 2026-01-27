//
//  TokenPriceChangeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

// [REDACTED_TODO_COMMENT]
struct TokenPriceChangeView: View {
    let state: State
    var showSkeletonWhenLoading: Bool = true
    var showSeparatorForNeutralStyle: Bool = true

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
            ZStack {
                styledDashText
                    .opacity(0.01)
                if showSkeletonWhenLoading {
                    SkeletonView()
                        .frame(size: loaderSize)
                        .cornerRadiusContinuous(3)
                }
            }
        case .loaded(let signType, let text):
            HStack(spacing: 4) {
                if shouldShowIcon(for: signType) {
                    signType.imageType.image
                        .renderingMode(.template)
                        .foregroundColor(signType.textColor)
                }

                styledText(text, textColor: signType.textColor)
            }
        }
    }

    private func shouldShowIcon(for signType: ChangeSignType) -> Bool {
        if signType == .neutral {
            return showSeparatorForNeutralStyle
        }
        return true
    }

    private var styledDashText: some View {
        styledText(AppConstants.enDashSign)
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

        var signType: ChangeSignType? {
            if case .loaded(let signType, _) = self {
                return signType
            }

            return nil
        }
    }
}
