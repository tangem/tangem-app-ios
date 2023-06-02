//
//  CardInfoPagePreviewView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPagePreviewView<HeaderPlaceholder>: View where HeaderPlaceholder: View {
    @ObservedObject var viewModel: CardInfoPagePreviewViewModel

    let headerPlaceholder: HeaderPlaceholder

    var body: some View {
        // [REDACTED_TODO_COMMENT]
        List {
            headerPlaceholder
                .listRowSeparatorHidden(backgroundColor: Constants.backgroundColor)
                .listRowBackground(Constants.backgroundColor)

            Spacer()
                .listRowSeparatorHidden(backgroundColor: Constants.backgroundColor)
                .listRowBackground(Constants.backgroundColor)

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
                    Spacer()
                        .listRowSeparatorHidden(backgroundColor: Constants.backgroundColor)
                        .listRowBackground(Constants.backgroundColor)
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func makeCell(
        sectionItem: CardInfoPageWarningPreviewSectionItem
    ) -> some View {
        switch sectionItem {
        case .iconAndTitle(let viewModel):
            CardInfoPageWarningIconAndTitleCellPreviewView(
                viewModel: viewModel,
                contentColor: Constants.contentColor
            )
        case .iconOnly(let viewModel):
            CardInfoPageWarningIconOnlyCellPreviewView(
                viewModel: viewModel,
                contentColor: Constants.contentColor
            )
        }
    }

    @ViewBuilder
    private func makeCell(
        sectionItem: CardInfoPageTransactionPreviewSectionItem
    ) -> some View {
        switch sectionItem {
        case .default(let viewModel):
            CardInfoPageTransactionDefaultCellPreviewView(
                viewModel: viewModel,
                contentColor: Constants.contentColor
            )
        }
    }

    @ViewBuilder
    private func prepareCell(
        cell: some View,
        forDisplayAtIndex index: Int,
        sectionItemsCount itemsCount: Int
    ) -> some View {
        let corners = corners(forCellAtIndex: index, sectionItemsCount: itemsCount)
        Group {
            if #available(iOS 15.0, *) {
                cell
                    .listRowBackground(Constants.backgroundColor)
                    .listRowInsets(.init(horizontal: Constants.horizontalOffset, vertical: 0.0))
                    .cornerRadius(Constants.cornerRadius, corners: corners)
            } else {
                cell
                    .frame(width: UIScreen.main.bounds.width - Constants.horizontalOffset * 2.0)
                    .cornerRadius(Constants.cornerRadius, corners: corners)
                    .infinityFrame(alignment: .center)
            }
        }
        .listRowSeparatorHidden(backgroundColor: Constants.backgroundColor)
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
        static var backgroundColor: Color { Colors.Background.secondary }
        static var contentColor: Color { Colors.Background.primary }
        static var horizontalOffset: CGFloat { 20.0 }
        static var cornerRadius: CGFloat { 14.0 }
    }
}

// MARK: - Convenience extensions

private extension View {
    func listRowSeparatorHidden(backgroundColor: Color) -> some View {
        modifier(ListRowSeparatorHiddenViewModifier(backgroundColor: backgroundColor))
    }
}

private struct ListRowSeparatorHiddenViewModifier: ViewModifier {
    var backgroundColor: Color

    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .listRowSeparator(.hidden)
        } else {
            // Based on https://stackoverflow.com/a/67055499
            content
                .listRowInsets(EdgeInsets(top: -1.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
                .background(backgroundColor)
        }
    }
}
