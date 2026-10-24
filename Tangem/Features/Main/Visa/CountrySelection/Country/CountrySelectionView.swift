//
//  CountrySelectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemUI

struct CountrySelectionView: View {
    @StateObject private var viewModel: CountrySelectionViewModel

    init(viewModel: @autoclosure @escaping () -> CountrySelectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        GeoSelectionContentView(
            state: viewModel.state,
            highlightedSectionTitle: viewModel.configuration.highlight?.sectionTitle,
            allSectionTitle: viewModel.configuration.highlight?.allSectionTitle,
            hasFlags: true,
            loadingItemId: viewModel.loadingItemId,
            onItemTap: viewModel.onItemTap(id:isHighlighted:)
        )
        .tangemSearchable(
            text: $viewModel.searchText,
            prompt: Localization.commonSearch,
            accessibilityIdentifier: TangemPayAccessibilityIdentifiers.geoSelectionSearchField
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .topNavigation(
            title: viewModel.configuration.title,
            leading: viewModel.configuration.leadingPolicy,
            onClose: viewModel.onClose
        )
    }
}
