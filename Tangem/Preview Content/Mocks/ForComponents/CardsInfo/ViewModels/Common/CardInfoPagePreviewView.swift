//
//  CardInfoPagePreviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPagePreviewView: View {
    @ObservedObject var viewModel: CardInfoPagePreviewViewModel

    let scrollViewConnector: CardsInfoPagerScrollViewConnector

    private let coordinateSpaceName = UUID()

    @State private var contentSize: CGSize = .zero
    @State private var viewportSize: CGSize = .zero

    var body: some View {
        ScrollView(showsIndicators: false) {
            // ScrollView inserts default spacing between its content views.
            // Wrapping content into `VStack` prevents it.
            // `LazyVStack` is still lazy while being wrapped in this way.
            VStack(spacing: 0.0) {
                LazyVStack(spacing: 0.0) {
                    scrollViewConnector.headerPlaceholderView

                    Spacer(minLength: Constants.spacerHeight)

                    ForEach(viewModel.sections, id: \.id) { section in
                        switch section.items {
                        case .transaction(let cellViewModels):
                            Section {
                                ForEach(cellViewModels.indexed(), id: \.1.id) { index, sectionItem in
                                    prepareCell(
                                        cell: makeCell(sectionItem: sectionItem),
                                        forDisplayAtIndex: index,
                                        sectionItemsCount: cellViewModels.count
                                    )
                                }
                            }
                        case .warning(let cellViewModels):
                            Section {
                                ForEach(cellViewModels.indexed(), id: \.1.id) { index, sectionItem in
                                    prepareCell(
                                        cell: makeCell(sectionItem: sectionItem),
                                        forDisplayAtIndex: index,
                                        sectionItemsCount: cellViewModels.count
                                    )
                                }
                            }
                        }

                        // Do not append spacing after the last section
                        if section.id != viewModel.sections.last?.id {
                            Spacer(minLength: Constants.spacerHeight)
                        }
                    }
                }
                .readGeometry(\.size, bindTo: $contentSize)
                .readContentOffset(
                    inCoordinateSpace: .named(coordinateSpaceName),
                    bindTo: scrollViewConnector.contentOffset
                )

                // An empty space at the bottom, adds enough room for the header to collapse
                // when there is not enough content in the ScrollView
                Spacer(
                    minLength: scrollViewConnector.footerViewHeight(
                        viewportSize: viewportSize,
                        contentSize: contentSize
                    )
                )
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .readGeometry(\.size, bindTo: $viewportSize)
    }

    @ViewBuilder
    private func makeCell(
        sectionItem: CardInfoPageWarningPreviewSectionItem
    ) -> some View {
        switch sectionItem {
        case .iconAndTitle(let viewModel):
            CardInfoPageWarningIconAndTitleCellPreviewView(viewModel: viewModel)
        case .iconOnly(let viewModel):
            CardInfoPageWarningIconOnlyCellPreviewView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func makeCell(
        sectionItem: CardInfoPageTransactionPreviewSectionItem
    ) -> some View {
        switch sectionItem {
        case .default(let viewModel):
            CardInfoPageTransactionDefaultCellPreviewView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func prepareCell(
        cell: some View,
        forDisplayAtIndex index: Int,
        sectionItemsCount itemsCount: Int
    ) -> some View {
        let corners = corners(forCellAtIndex: index, sectionItemsCount: itemsCount)
        cell
            .infinityFrame()
            .background(Constants.contentColor)
            .cornerRadius(Constants.cornerRadius, corners: corners)
            .padding(.horizontal, Constants.cellPadding)
    }

    private func corners(
        forCellAtIndex index: Int,
        sectionItemsCount itemsCount: Int
    ) -> UIRectCorner {
        guard itemsCount > 1 else { return .allCorners }

        switch index {
        case 0:
            return [.topLeft, .topRight]
        case itemsCount - 1:
            return [.bottomLeft, .bottomRight]
        default:
            return []
        }
    }
}

// MARK: - Constants

private extension CardInfoPagePreviewView {
    private enum Constants {
        static var contentColor: Color { Colors.Background.primary }
        static var cornerRadius: CGFloat { 14.0 }
        static var spacerHeight: CGFloat { 14.0 }
        static var cellPadding: CGFloat { 16.0 }
    }
}
