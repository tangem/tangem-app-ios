//
//  AddCustomTokenDerivationPathSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AddCustomTokenDerivationPathSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddCustomTokenDerivationPathSelectorCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AddCustomTokenDerivationPathSelectorView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.derivationPathWriterViewModel) {
                AddCustomTokenDerivationPathWriterView(viewModel: $0)
            }
    }
}
