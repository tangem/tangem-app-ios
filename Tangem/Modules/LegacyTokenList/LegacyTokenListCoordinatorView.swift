//
//  LegacyTokenListCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct LegacyTokenListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: LegacyTokenListCoordinator

    var body: some View {
        NavigationView {
            ZStack {
                if let model = coordinator.tokenListViewModel {
                    LegacyTokenListView(viewModel: model)
                        .navigationLinks(links)
                    #warning("[REDACTED_TODO_COMMENT]")
                    sheets
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addCustomTokenViewModel) {
                LegacyAddCustomTokenView(viewModel: $0)
            }
            .emptyNavigationLink()
    }

    #warning("[REDACTED_TODO_COMMENT]")
    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.addCustomTokenCoordinator) {
                AddCustomTokenCoordinatorView(coordinator: $0)
            }
    }
}
