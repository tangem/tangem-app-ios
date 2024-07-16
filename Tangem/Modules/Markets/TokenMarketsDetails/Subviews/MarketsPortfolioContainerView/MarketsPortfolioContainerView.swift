//
//  MarketsPortfolioContainerView.swift
//  Tangem
//
//  Created by skibinalexander on 11.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsPortfolioContainerView: View {
    @ObservedObject var viewModel: MarketsPortfolioContainerViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 14) {
            // Token list block
            VStack(alignment: .leading, spacing: .zero) {
                headerView

                contentView
            }

            // Quick action block
            quickActionsView
        }
        .if(viewModel.tokenItemViewModels.isEmpty) { view in
            view.defaultRoundedBackground(with: Colors.Background.action)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .center) {
                Text(Localization.marketsCommonMyPortfolio)
                    .lineLimit(1)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if viewModel.isShowTopAddButton {
                    Button(action: {
                        viewModel.onAddTapAction()
                    }, label: {
                        HStack(spacing: 2) {
                            Assets.plus24.image
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.primary1)
                                .frame(size: .init(bothDimensions: 14))

                            Text(Localization.marketsAddToken)
                                .style(Fonts.Regular.footnote.bold(), color: Colors.Text.primary1)
                        }
                    })
                    .padding(.leading, 8)
                    .padding(.trailing, 10)
                    .padding(.vertical, 4)
                    .roundedBackground(with: Colors.Button.secondary, padding: .zero, radius: 8)
                }
            }
        }
        .modifier(if: viewModel.tokenItemViewModels.isEmpty, then: { headerView in
            headerView
                .padding(.bottom, 10)
        }, else: { headerView in
            headerView
                .padding(.top, 14)
                .padding(.horizontal, 14)
                .padding(.bottom, Constants.defaultVerticalOffsetSpacingBetweenContent + 10)
                .background(Colors.Background.action)
                .modifier(HeaderCornerRadiusModify())
        })
    }

    private var contentView: some View {
        VStack(spacing: .zero) {
            switch viewModel.typeView {
            case .empty:
                emptyView
            case .list:
                listView
            case .unavailable:
                unavailableView
            }
        }
    }

    private var listView: some View {
        LazyVStack(spacing: .zero) {
            let elementItems = viewModel.tokenItemViewModels

            ForEach(indexed: elementItems.indexed()) { itemIndex, itemViewModel in
                if #available(iOS 16.0, *) {
                    let isFirstItem = itemIndex == 0
                    let isLastItem = itemIndex == elementItems.count - 1

                    if isFirstItem {
                        let isSingleItem = elementItems.count == 1

                        MarketsPortfolioTokenItemView(
                            viewModel: itemViewModel,
                            cornerRadius: Constants.cornerRadius,
                            roundedCornersVerticalEdge: isSingleItem ? .all : .topEdge
                        )
                    } else if isLastItem {
                        MarketsPortfolioTokenItemView(
                            viewModel: itemViewModel,
                            cornerRadius: Constants.cornerRadius,
                            roundedCornersVerticalEdge: .bottomEdge
                        )
                    } else {
                        MarketsPortfolioTokenItemView(
                            viewModel: itemViewModel,
                            cornerRadius: Constants.cornerRadius,
                            roundedCornersVerticalEdge: nil
                        )
                    }
                } else {
                    MarketsPortfolioTokenItemView(
                        viewModel: itemViewModel,
                        cornerRadius: Constants.cornerRadius
                    )
                }
            }
        }
        .background(Colors.Background.action.cornerRadiusContinuous(Constants.cornerRadius))
        .offset(y: -Constants.defaultVerticalOffsetSpacingBetweenContent)
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.marketsAddToMyPortfolioDescription)
                .lineLimit(2)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            MainButton(title: Localization.marketsAddToPortfolioButton) {
                viewModel.onAddTapAction()
            }
        }
    }

    private var unavailableView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text(Localization.marketsAddToMyPortfolioUnavailableDescription)
                    .style(.footnote, color: Colors.Text.tertiary)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var quickActionsView: some View {
        if viewModel.showQuickActions, let tokenItemViewModel = viewModel.tokenItemViewModels.first {
            MarketsPortfolioQuickActionsView(
                actions: viewModel.buildContextActions(for: tokenItemViewModel),
                onTapAction: { actionType in
                    viewModel.didTapContextAction(actionType, for: tokenItemViewModel)
                }
            )
        }
    }
}

extension MarketsPortfolioContainerView {
    enum TypeView: Int, Identifiable, Hashable {
        case empty
        case list
        case unavailable

        var id: Int {
            rawValue
        }
    }
}

private extension MarketsPortfolioContainerView {
    enum Constants {
        static let cornerRadius: CGFloat = 14.0
        static let defaultVerticalOffsetSpacingBetweenContent: CGFloat = 14
    }
}

private extension MarketsPortfolioContainerView {
    struct HeaderCornerRadiusModify: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 16.0, *) {
                content
                    .cornerRadiusContinuous(topLeadingRadius: Constants.cornerRadius, topTrailingRadius: Constants.cornerRadius)
            } else {
                content
                    .cornerRadius(20, corners: [.topLeft, .topRight])
            }
        }
    }
}
