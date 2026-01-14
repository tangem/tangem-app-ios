//
//  NewsListCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct NewsListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: NewsListCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                NewsListView(viewModel: viewModel)
            }
        }
        .bindAlert($coordinator.error)
    }
}
