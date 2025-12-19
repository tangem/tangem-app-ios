//
//  OnrampCountrySelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemExpress
import TangemUI
import TangemAccessibilityIdentifiers

struct OnrampCountrySelectorView: View {
    @ObservedObject var viewModel: OnrampCountrySelectorViewModel

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            GrabberView()

            CustomSearchBar(
                searchText: $viewModel.searchText,
                placeholder: Localization.onrampCountrySearch,
                keyboardType: .alphabet,
                style: .translucent,
                clearButtonAction: {
                    viewModel.searchText = ""
                },
                cancelButtonAction: {
                    viewModel.searchText = ""
                }
            )
            .accessibilityIdentifier(OnrampAccessibilityIdentifiers.residenceSearchField)
            .padding(.horizontal, 16)

            contentView
        }
        .background(Colors.Background.primary.ignoresSafeArea())
    }
}

private extension OnrampCountrySelectorView {
    @ViewBuilder
    var contentView: some View {
        switch viewModel.countries {
        case .loading:
            skeletonsView
                .transition(.opacityLinear())
        case .success(let data):
            countriesView(data: data)
                .transition(.opacityLinear())
        case .failure:
            failedToLoadView
                .transition(.opacityLinear())
        }
    }

    @ViewBuilder
    var failedToLoadView: some View {
        Spacer()

        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: viewModel.loadCountries
        )

        Spacer()
    }

    var skeletonsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .zero) {
                ForEach(0 ..< 20) { _ in
                    OnrampCountrySkeletonView()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func countriesView(data: [OnrampCountryViewData]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .zero) {
                ForEach(data) { data in
                    OnrampCountryView(data: data)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
