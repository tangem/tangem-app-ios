//
//  NewsDeeplinkCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewsDeeplinkCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: NewsDeeplinkCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                NewsDeeplinkView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) { tokenCoordinator in
                MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                    .navigationBarHidden(true)
            }
    }
}
