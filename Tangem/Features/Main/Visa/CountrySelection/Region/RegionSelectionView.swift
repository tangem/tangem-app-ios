//
//  RegionSelectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemUI

struct RegionSelectionView: View {
    @StateObject private var viewModel: RegionSelectionViewModel

    init(viewModel: @autoclosure @escaping () -> RegionSelectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        GeoSelectionContentView(
            state: viewModel.state,
            highlightedSectionTitle: viewModel.configuration.highlight?.sectionTitle,
            allSectionTitle: viewModel.configuration.highlight?.allSectionTitle,
            hasFlags: false,
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
