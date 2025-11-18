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

    private var geometryEffect: GeometryEffectPropertiesModel?

    init(coordinator: AuthCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationView {
            content
                .navigationLinks(links)
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                AuthView(viewModel: rootViewModel)
                    .setGeometryEffect(geometryEffect)
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
            .emptyNavigationLink()
    }
}

extension AuthCoordinatorView: Setupable {
    func setGeometryEffect(_ geometryEffect: GeometryEffectPropertiesModel) -> Self {
        map { $0.geometryEffect = geometryEffect }
    }
}
