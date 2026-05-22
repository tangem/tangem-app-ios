//
//  NewsDeeplinkContainerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct NewsDeeplinkContainerView: View {
    @StateObject private var coordinator: NewsDeeplinkCoordinator

    init(newsId: Int, dismissAction: @escaping () -> Void) {
        _coordinator = StateObject(
            wrappedValue: NewsDeeplinkCoordinator(newsId: newsId, dismissAction: dismissAction)
        )
    }

    var body: some View {
        NewsPagerView(viewModel: coordinator.viewModel)
            .navigationLinks(tokenDetailsLinks)
    }

    private var tokenDetailsLinks: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) { tokenCoordinator in
                MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                    .ignoresSafeArea(.container, edges: .top)
            }
    }
}
