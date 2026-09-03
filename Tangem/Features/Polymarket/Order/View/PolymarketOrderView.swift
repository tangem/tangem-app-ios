//
//  PolymarketOrderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketOrderView: View {
    @ObservedObject private var viewModel: PolymarketOrderViewModel

    init(viewModel: PolymarketOrderViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
                .infinityFrame()

            topBar
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    // MARK: - Top bar

    private var topBar: some View {
        backButton
            .padding(.horizontal, Constants.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: Constants.toolbarHeight)
    }

    private var backButton: some View {
        SwiftUI.Button(action: viewModel.dismiss) {
            DesignSystem.Icons.ChevronLeft.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(size: .init(bothDimensions: Constants.barButtonSide))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
        .accessibilityLabel(Localization.commonBack)
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: Constants.spacing) {
            Text(viewModel.market.groupItemTitle ?? viewModel.market.title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(viewModel.outcome.title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .padding(Constants.padding)
    }
}

// MARK: - Constants

private extension PolymarketOrderView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let padding: CGFloat = 16
        static let toolbarHeight: CGFloat = 44
        static let barButtonSide: CGFloat = 44
    }
}
