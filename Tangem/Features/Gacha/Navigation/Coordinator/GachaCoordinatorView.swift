//
//  GachaCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct GachaCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: GachaCoordinator

    var body: some View {
        if let state = coordinator.state {
            switch state {
            case .welcome(let viewModel):
                GachaWelcomeView(viewModel: viewModel, onCloseButtonAction: coordinator.dismiss)
            case .main(let viewModel):
                GachaMainView(viewModel: viewModel, onBackButtonAction: coordinator.dismiss)
            }
        }
    }
}
