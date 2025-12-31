//
//  NewsListCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI

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
                    .navigationBarHidden(true)
                    .navigation(item: tokenDetailsBinding) { tokenCoordinator in
                        MarketsTokenDetailsCoordinatorView(coordinator: tokenCoordinator)
                            .navigationBarHidden(true)
                    }
            }
    }

    // MARK: - Bindings

    private var pagerBinding: Binding<NewsPagerViewModel?> {
        Binding(
            get: {
                guard case .pager(let id) = coordinator.path.first(where: {
                    if case .pager = $0 { return true }
                    return false
                }) else { return nil }
                return coordinator.pagerViewModel(for: id)
            },
            set: { newValue in
                if newValue == nil {
                    coordinator.path.removeAll { destination in
                        if case .pager = destination { return true }
                        return false
                    }
                }
            }
        )
    }

    private var tokenDetailsBinding: Binding<MarketsTokenDetailsCoordinator?> {
        Binding(
            get: {
                guard case .tokenDetails(let id) = coordinator.path.first(where: {
                    if case .tokenDetails = $0 { return true }
                    return false
                }) else { return nil }
                return coordinator.tokenDetailsCoordinator(for: id)
            },
            set: { newValue in
                if newValue == nil {
                    coordinator.path.removeAll { destination in
                        if case .tokenDetails = destination { return true }
                        return false
                    }
                }
            }
        )
    }
}
