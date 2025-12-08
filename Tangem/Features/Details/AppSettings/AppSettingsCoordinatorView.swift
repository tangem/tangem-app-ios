//
//  AppSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

struct AppSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AppSettingsCoordinator

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            AppSettingsView(viewModel: rootViewModel)
                .navigationLinks(links)
        } else if let newRootViewModel = coordinator.newRootViewModel {
            NewAppSettingsView(viewModel: newRootViewModel)
                .navigationLinks(links)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.currencySelectViewModel) {
                CurrencySelectView(viewModel: $0)
            }
            .navigation(item: $coordinator.themeSelectionViewModel) {
                ThemeSelectionView(viewModel: $0)
            }
    }
}
