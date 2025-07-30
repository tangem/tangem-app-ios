//
//  AuthCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct AuthCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AuthCoordinator

    private var namespace: Namespace.ID?

    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            content
                .navigationLinks(links)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AuthView(viewModel: rootViewModel)
                    .setNamespace(namespace)
            }

            if let rootViewModel = coordinator.newRootViewModel {
                NewAuthView(viewModel: rootViewModel)
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.createWalletSelectorCoordinator) {
                CreateWalletSelectorCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.importWalletSelectorCoordinator) {
                ImportWalletSelectorCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.hotAccessCodeViewModel) {
                HotAccessCodeView(viewModel: $0)
            }
    }
}

extension AuthCoordinatorView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }
}
