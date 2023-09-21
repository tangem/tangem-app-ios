//
//  AddCustomTokenDerivationPathSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenDerivationPathSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddCustomTokenDerivationPathSelectorCoordinator

    init(coordinator: AddCustomTokenDerivationPathSelectorCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AddCustomTokenDerivationPathSelectorView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        EmptyView()
    }
}
