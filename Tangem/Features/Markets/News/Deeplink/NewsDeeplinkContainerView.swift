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

    init(newsId: Int) {
        _coordinator = StateObject(wrappedValue: NewsDeeplinkCoordinator(newsId: newsId))
    }

    var body: some View {
        NewsPagerView(viewModel: coordinator.viewModel)
            .navigationLinks(tokenDetailsLinks)
    }

    private var tokenDetailsLinks: some View {
        NavHolder()
            .navigation(item: tokenDetailsBinding) { tokenCoordinator in
                MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                    .ignoresSafeArea(.container, edges: .top)
            }
    }

    private var tokenDetailsBinding: Binding<MarketsTokenDetailsCoordinator?> {
        Binding(
            get: {
                coordinator.path.first(where: \.isTokenDetails)?.tokenDetailsValue
            },
            set: { newValue in
                if newValue == nil {
                    coordinator.path.removeAll(where: \.isTokenDetails)
                }
            }
        )
    }
}
