//
//  PulseView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct PulseView: View {
    @ObservedObject var viewModel: PulseViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
                .padding(.horizontal, Constants.horizontalPadding)

            if viewModel.isCategoriesExpanded {
                categoriesRow
            }

            if viewModel.isFailed, viewModel.tokens.isEmpty {
                TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.onRetry)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.errorVerticalPadding)
            } else if viewModel.tokens.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(0 ..< Constants.skeletonRowCount, id: \.self) { _ in
                        TokenRowMarket(.shimmer)
                    }
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.tokens) { token in
                        MarketTokenRowView(viewModel: token)
                            .onAppear { viewModel.onTokenAppear(token) }
                            .onDisappear { viewModel.onTokenDisappear(token) }
                    }
                }
            }
        }
        .onAppear(perform: viewModel.onViewAppear)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isCategoriesExpanded)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsPulseCommonTitle)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            HStack(spacing: 16) {
                categoriesButton

                Spacer()

                ForEach(viewModel.intervals, id: \.self) { interval in
                    SwiftUI.Button {
                        viewModel.onSelectInterval(interval)
                    } label: {
                        chip(interval.title, isSelected: interval == viewModel.selectedInterval)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoriesButton: some View {
        SwiftUI.Button {
            viewModel.onToggleCategories()
        } label: {
            HStack(spacing: 4) {
                Text("Categories")
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                DesignSystem.Icons.ChevronDown.regular16.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.chevronIconSize, height: Constants.chevronIconSize)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .rotationEffect(.degrees(viewModel.isCategoriesExpanded ? 180 : 0))
            }
        }
        .buttonStyle(.plain)
    }

    private var categoriesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.self) { category in
                    SwiftUI.Button {
                        viewModel.onSelectCategory(category)
                    } label: {
                        chip(category.title, isSelected: category == viewModel.selectedCategory)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    private func chip(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .style(
                DesignSystem.Font.subheadingMediumToken,
                color: isSelected ? DesignSystem.Color.textPrimary : DesignSystem.Color.textTertiary
            )
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background {
                if isSelected {
                    Capsule().fill(DesignSystem.Color.bgTertiary)
                }
            }
    }
}

// MARK: - Constants

private extension PulseView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let chevronIconSize: CGFloat = 16
        static let skeletonRowCount = 20
        static let errorVerticalPadding: CGFloat = 24
    }
}
