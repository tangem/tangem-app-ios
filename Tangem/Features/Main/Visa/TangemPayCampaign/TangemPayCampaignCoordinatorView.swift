//
//  TangemPayCampaignCoordinatorView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct TangemPayCampaignCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayCampaignCoordinator

    var body: some View {
        ZStack {
            // `topNavigation` renders through the SwiftUI toolbar, which needs a navigation container
            // to attach to — without one the campaign screens lose their title and close button.
            NavigationStack {
                if let rootViewModel = coordinator.rootViewModel {
                    TangemPayCampaignView(viewModel: rootViewModel)
                }
            }

            sheets
        }
        .sheet(item: $coordinator.legalDocumentViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: TangemPayCardsLimitReachedSheetViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayMaximumCardsIssuedSheetViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
    }
}
