//
//  ThemeSelectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ThemeSelectionView: View {
    @ObservedObject var viewModel: ThemeSelectionViewModel

    var body: some View {
        GroupedScrollView {
            GroupedSection(viewModel.themeViewModels) {
                DefaultSelectableRowView(data: $0, selection: $viewModel.currentThemeOption)
            } footer: {
                DefaultFooterView(Localization.appSettingsThemeSelectionFooter)
            }
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.ignoresSafeArea(edges: .all))
        .navigationTitle(Text(Localization.appSettingsThemeSelectorTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeSelectionView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ThemeSelectionView(viewModel: .init())
        }
    }
}
