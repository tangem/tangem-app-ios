//
//  CountrySelectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct CountrySelectionView: View {
    @StateObject private var viewModel: CountrySelectionViewModel

    init(viewModel: @autoclosure @escaping () -> CountrySelectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            GeoSelectionContentView(
                state: viewModel.state,
                suggestedSectionTitle: viewModel.configuration.suggestedSectionTitle,
                allSectionTitle: viewModel.configuration.allSectionTitle,
                hasFlags: true,
                onItemTap: viewModel.onItemTap(id:)
            )
            .tangemSearchable(text: $viewModel.searchText, prompt: Localization.commonSearch)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .topNavigation(
                title: viewModel.configuration.title,
                onClose: viewModel.onClose
            )
        }
    }
}
