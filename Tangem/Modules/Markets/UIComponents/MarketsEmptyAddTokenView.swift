//
//  MarketsEmptyAddTokenView.swift
//  Tangem
//
//  Created by skibinalexander on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsEmptyAddTokenView: View {
    // MARK: - Properties

    private(set) var didTapAction: (() -> Void)?

    // MARK: - UI

    var body: some View {
        VStack(spacing: 12) {
            headerView

            buttonView
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(Localization.marketsCommonMyPortfolio)
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Text(Localization.marketsAddToMyPortfolioDescription)
                    .lineLimit(2)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            Spacer()
        }
    }

    private var buttonView: some View {
        MainButton(title: Localization.marketsAddToPortfolioButton) {
            didTapAction?()
        }
    }
}

#Preview {
    MarketsEmptyAddTokenView()
}
