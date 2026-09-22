//
//  CryptoSearchPortfolioTokenRow.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CryptoSearchPortfolioTokenRow: View {
    @ObservedObject var viewModel: MarketsPortfolioTokenListRowViewModel
    @ObservedObject private var visibilityState = SensitiveTextVisibilityState.shared

    let onTap: (() -> Void)?

    var body: some View {
        content
            .disabled(onTap == nil)
            .environment(\.isBalanceMasked, visibilityState.isHidden)
            .environment(\.isShimmerActive, true)
    }

    @ViewBuilder
    private var content: some View {
        if let content = viewModel.tokenRowContent(onTap: { onTap?() }) {
            TokenRow(content)
        } else {
            SwiftUI.Button(action: { onTap?() }) {
                MarketsPortfolioTokenListRowView(viewModel: viewModel)
                    .padding(Constants.legacyRowPadding)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Constants

private extension CryptoSearchPortfolioTokenRow {
    enum Constants {
        static let legacyRowPadding: CGFloat = 16
    }
}
