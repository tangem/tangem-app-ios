//
//  TangemPayOrderCardCoordinatorView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayOrderCardCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayOrderCardCoordinator

    var body: some View {
        NavigationStack {
            if let viewModel = coordinator.orderCardTypeViewModel {
                TangemPayOrderCardTypeView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.orderCardDataViewModel) { viewModel in
                TangemPayOrderCardDataView(viewModel: viewModel)
                    .navigationLinks(successLinks)
            }
    }

    private var successLinks: some View {
        NavHolder()
            .navigation(item: $coordinator.orderCardSuccessViewModel) {
                TangemPayOrderCardSuccessView(viewModel: $0)
            }
    }
}
