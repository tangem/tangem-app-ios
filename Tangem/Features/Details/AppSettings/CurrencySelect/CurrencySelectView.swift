//
//  CurrencySelectView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct CurrencySelectView: View {
    @ObservedObject var viewModel: CurrencySelectViewModel

    var body: some View {
        ZStack {
            Colors.Background.secondary.ignoresSafeArea()
            content
        }
        .navigationTitle(Localization.detailsRowTitleCurrency)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.handle(viewEvent: .viewDidAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state.contentState {
        case .loading:
            ProgressView()
                .controlSize(.regular)

        case .success(let currencies):
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: .zero) {
                    GroupedSection(currencies) { currency in
                        currencyView(currency)
                    }
                    .innerContentPadding(14)
                    .interItemSpacing(12)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .searchable(
                text: Binding(
                    get: { viewModel.state.searchText },
                    set: { viewModel.handle(viewEvent: .searchTextUpdated($0)) }
                ),
                placement: searchFieldPlacement
            )

        case .failure(let error):
            Text(error.localizedDescription)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .padding(.horizontal, 16)
        }
    }

    private func currencyView(_ currency: CurrencySelectViewState.CurrencyItem) -> some View {
        Button(action: { viewModel.handle(viewEvent: .currencySelected(currency)) }) {
            HStack(spacing: .zero) {
                Text(currency.title)
                    .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                if currency.isSelected {
                    Spacer()

                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 16, height: 16)
                        .foregroundColor(Colors.Icon.accent)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
    }

    private var searchFieldPlacement: SearchFieldPlacement {
        if #available(iOS 26.0, *) {
            return SearchFieldPlacement.automatic
        } else {
            return SearchFieldPlacement.navigationBarDrawer(displayMode: .always)
        }
    }
}

struct CurrencySelectView_Preview: PreviewProvider {
    private final class CurrencySelectRoutableMock: CurrencySelectRoutable {
        func dismissCurrencySelect() {}
    }

    static var previews: some View {
        NavigationStack {
            CurrencySelectView(
                viewModel: CurrencySelectViewModel(
                    coordinator: CurrencySelectRoutableMock()
                )
            )
        }
    }
}
