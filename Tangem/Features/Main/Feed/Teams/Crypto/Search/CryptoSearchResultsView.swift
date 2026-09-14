//
//  CryptoSearchResultsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct CryptoSearchResultsView: View {
    let results: [CryptoSearchResult]
    let onSelect: (CryptoSearchResult) -> Void
    let onAppear: (CryptoSearchResult) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(results) { result in
                row(for: result)
            }
        }
        .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 0, radius: Constants.cornerRadius)
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

// MARK: - Subviews

private extension CryptoSearchResultsView {
    func row(for result: CryptoSearchResult) -> some View {
        Row(title: result.name, subtitle: result.symbol, value: result.price, subvalue: result.change)
            .start { TokenIconV2(tokenIconInfo: result.icon, size: Constants.iconSize) }
            .contentLead(.end)
            .overrideTextColors(RowOverrideTextColors(subvalue: changeColor(for: result)))
            .showDivider(result.id != results.last?.id)
            .onTap { onSelect(result) }
            .onAppear { onAppear(result) }
    }

    func changeColor(for result: CryptoSearchResult) -> Color {
        result.isPositive ? DesignSystem.Color.textAccentBlue : DesignSystem.Color.textAccentRed
    }
}

// MARK: - Constants

private extension CryptoSearchResultsView {
    enum Constants {
        static let iconSize = TokenIconV2.Size.size40
        static let cornerRadius: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
    }
}
