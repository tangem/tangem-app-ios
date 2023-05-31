//
//  PromotionCoordinatorView.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct PromotionCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PromotionCoordinator

    init(coordinator: PromotionCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                PromotionView(viewModel: rootViewModel)
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
