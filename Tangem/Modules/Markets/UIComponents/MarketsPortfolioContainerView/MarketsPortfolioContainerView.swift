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
        VStack(alignment: .leading, spacing: 12) {
            headerView

            contentView
        }
        .roundedBackground(with: Colors.Background.action, padding: 14, radius: 14)
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
                        HStack {
                            Assets
                                .plus24
                                .image
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.primary1)
                                .frame(size: .init(bothDimensions: 14))

                            Text("Add token")
                                .style(Fonts.Regular.footnote.bold(), color: Colors.Text.primary1)
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 10)
                        .padding(.vertical, 2)
                    })
                    .roundedBackground(with: Colors.Button.secondary, padding: .zero, radius: 8)
                }
            }
        }
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
        VStack {
            ForEach(viewModel.tokenItemViewModels) {
                MarketsPortfolioTokenItemView(viewModel: $0)
            }
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                Text("This asset is not available")
                    .style(.footnote, color: Colors.Text.tertiary)

                Spacer()
            }
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

#Preview {
    EmptyView()
}
