//
//  NewsListCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct NewsListCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: NewsListCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                NewsListView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
        .bindAlert($coordinator.error)
    }

    private var links: some View {
        NavHolder()
            .navigation(item: pagerBinding) { viewModel in
                NewsPagerView(viewModel: viewModel)
                    .navigationLinks(tokenDetailsLinks)
            }
    }

    private var tokenDetailsLinks: some View {
        NavHolder()
            .navigation(item: tokenDetailsBinding) { tokenCoordinator in
                MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                    .ignoresSafeArea(.container, edges: .top)
            }
    }

    // MARK: - Bindings

    private var pagerBinding: Binding<NewsPagerViewModel?> {
        Binding(
            get: {
                coordinator.path.first(where: \.isPager)?.pagerValue
            },
            set: { newValue in
                if newValue == nil {
                    coordinator.path.removeAll(where: \.isPager)
                }
            }
        )
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
