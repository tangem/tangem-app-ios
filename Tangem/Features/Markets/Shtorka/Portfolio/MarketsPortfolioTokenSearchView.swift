//
//  MarketsPortfolioTokenSearchView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MarketsPortfolioTokenSearchView: View {
    typealias ViewModel = MarketsPortfolioTokenSearchViewModel

    @ScaledMetric private var contentSpacing: CGFloat = .unit(.x2)
    @ScaledMetric private var itemsSpacing: CGFloat = .unit(.x2)

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .animation(.default, value: viewModel.items)
    }
}

// MARK: - Subviews

private extension MarketsPortfolioTokenSearchView {
    var content: some View {
        VStack(spacing: contentSpacing) {
            collapsedItems

            if viewModel.hasShowAll {
                expandableContainer
            }
        }
    }

    var collapsedItems: some View {
        itemsView(viewModel.collapsedItems)
    }

    var expandedItems: some View {
        itemsView(viewModel.expandedItems)
    }

    func itemsView(_ items: [ViewModel.Item]) -> some View {
        LazyVStack(spacing: itemsSpacing) {
            ForEach(items) { item in
                itemView(item)
            }
        }
    }

    @ViewBuilder
    func itemView(_ item: ViewModel.Item) -> some View {
        switch item.data {
        case .single(let model):
            MarketsPortfolioSingleTokenView(viewModel: model)
        case .multiple(let model):
            MarketsPortfolioMultipleTokenView(viewModel: model)
        }
    }

    var expandableContainer: some View {
        ExpandableContainer(
            isExpanded: viewModel.isExpanded,
            footer: {
                showAllButton
            },
            content: {
                expandedItems
            }
        )
    }

    var showAllButton: some View {
        TangemButton(
            content: .combined(
                text: viewModel.showAllTitle,
                icon: viewModel.showAllImage,
                iconPosition: .right
            ),
            action: viewModel.onShowAllTap
        )
        .setStyleType(.secondary)
        .setCornerStyle(.rounded)
        .setSize(.x7)
    }
}

// MARK: - ExpandableContainer

private struct ExpandableContainer<Footer: View, Content: View>: View {
    @ScaledMetric private var verticalSpacing: CGFloat = .unit(.x2)

    private var height: CGFloat? {
        isExpanded ? nil : 0
    }

    private var spacing: CGFloat {
        isExpanded ? verticalSpacing : 0
    }

    private let isExpanded: Bool
    private let footer: Footer
    private let content: Content

    init(
        isExpanded: Bool,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.isExpanded = isExpanded
        self.footer = footer()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
                .frame(height: height, alignment: .top)
                .clipped()

            footer
        }
        .animation(.default, value: isExpanded)
    }
}
