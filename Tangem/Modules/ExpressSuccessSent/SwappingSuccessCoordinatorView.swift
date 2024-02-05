//
//  SwappingSuccessCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SwappingSuccessCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: SwappingSuccessCoordinator

    init(coordinator: SwappingSuccessCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        if let rootViewModel = coordinator.rootViewModel {
            ExpressSuccessSentView(viewModel: rootViewModel)
        }
    }
}
