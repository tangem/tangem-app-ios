//
//  RegionSelectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct RegionSelectionView: View {
    @StateObject private var viewModel: RegionSelectionViewModel

    init(viewModel: @autoclosure @escaping () -> RegionSelectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            GeoSelectionContentView(
                state: viewModel.state,
                suggestedSectionTitle: viewModel.configuration.suggestedSectionTitle,
                allSectionTitle: viewModel.configuration.allSectionTitle,
                hasFlags: false,
                onItemTap: viewModel.onItemTap(id:)
            )
            .tangemSearchable(text: $viewModel.searchText, prompt: Localization.commonSearch)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .topNavigation(
                title: viewModel.configuration.title,
                leading: viewModel.configuration.leadingPolicy,
                onClose: viewModel.onClose
            )
        }
    }
}
