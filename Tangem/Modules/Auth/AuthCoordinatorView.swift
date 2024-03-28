//
//  AuthCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct AuthCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AuthCoordinator

    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            content
            
            sheets
        }
        .animation(.default, value: coordinator.mainCoordinator == nil)
        .navigationBarHidden(coordinator.mainCoordinator == nil)
    }

    @ViewBuilder
    private var content: some View {
        if let mainCoordinator = coordinator.mainCoordinator {
            MainCoordinatorView(coordinator: mainCoordinator)
        } else if let authViewModel = coordinator.rootViewModel {
            AuthView(viewModel: authViewModel)
                .navigationLinks(links)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
