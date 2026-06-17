//
//  RedesignActionButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct RedesignActionButtonsView: View {
    @ObservedObject var viewModel: ActionButtonsViewModel

    @ScaledMetric private var spacing: CGFloat = .unit(.x3)
    @ScaledMetric private var horizontalPadding: CGFloat = .unit(.x15)

    private var dynamicHorizontalPadding: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let defaultScreenWidth: CGFloat = 390
        return horizontalPadding * screenWidth / defaultScreenWidth
    }

    var body: some View {
        let visibility = viewModel.actionButtonsVisibility

        ColumnContainer(minWidth: TangemMainActionButton.Size.buttonSide, spacing: spacing) {
            if visibility.isExchangeVisible {
                RedesignActionButtonView(viewModel: viewModel.buyActionButtonViewModel)
                    .disabled(viewModel.isRedesignActionDisabled(viewModel.buyActionButtonViewModel))
            }

            if visibility.isSwappingVisible {
                RedesignActionButtonView(viewModel: viewModel.swapActionButtonViewModel)
                    .disabled(viewModel.isRedesignActionDisabled(viewModel.swapActionButtonViewModel))
            }

            if visibility.isExchangeVisible {
                RedesignActionButtonView(viewModel: viewModel.sellActionButtonViewModel)
                    .disabled(viewModel.isRedesignActionDisabled(viewModel.sellActionButtonViewModel))
            }
        }
        .padding(.horizontal, dynamicHorizontalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.actionButtonsList)
    }
}

// MARK: - ColumnContainer

/// A layout that arranges its subviews horizontally in equal-width columns.
///
/// All columns share the same width, computed as the largest of:
/// - `minWidth` (a hard lower bound, e.g. the button size), and
/// - the smaller of each column's natural content width and an even share
///   of the container (`(containerWidth - totalSpacing) / count`).
///
/// - Parameters:
///   - minWidth: The minimum width each column is allowed to have.
///   - spacing: The horizontal gap inserted between adjacent columns.
private struct ColumnContainer: Layout {
    private let minWidth: CGFloat
    private let spacing: CGFloat

    init(
        minWidth: CGFloat,
        spacing: CGFloat
    ) {
        self.minWidth = minWidth
        self.spacing = spacing
    }

    struct Cache {
        var width: CGFloat
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache(width: 0)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = columnWidth(proposal: proposal, subviews: subviews)
        cache.width = width

        let fitsHeight = subviews.map { $0.sizeThatFits(.init(width: width, height: nil)).height }.max() ?? 0
        let count = CGFloat(subviews.count)
        let fitsWidth = width * count + spacing * max(0, count - 1)

        return CGSize(width: fitsWidth, height: fitsHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        var x = bounds.minX
        for subview in subviews {
            subview.place(
                at: CGPoint(x: x + cache.width / 2, y: bounds.minY),
                anchor: .top,
                proposal: .init(width: cache.width, height: nil)
            )
            x += cache.width + spacing
        }
    }

    private func columnWidth(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        let count = CGFloat(subviews.count)
        guard count > 0 else { return 0 }

        let maxFitsWidth = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? minWidth
        let totalSpacing = spacing * (CGFloat(count) - 1)
        let containerWidth = proposal.width ?? (maxFitsWidth * count + totalSpacing)
        let maxColumnWidth = (containerWidth - totalSpacing) / count

        return max(minWidth, min(maxFitsWidth, maxColumnWidth))
    }
}
