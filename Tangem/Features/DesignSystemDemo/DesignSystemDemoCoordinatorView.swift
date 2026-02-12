//
//  DesignSystemDemoCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct DesignSystemDemoCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: DesignSystemDemoCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                DesignSystemDemoView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.typoCoordinator) {
                TypographyDemoCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.buttonsCoordinator) {
                ButtonComponentDemoCoordinatorView(coordinator: $0)
            }
    }

    private var sheets: some View {
        EmptyView()
    }
}

struct DesignSystemDemoView: View {
    @ObservedObject var viewModel: DesignSystemDemoViewModel

    var body: some View {
        VStack(spacing: 8) {
            MainButton(title: "Typography") {
                viewModel.openTypo()
            }

            MainButton(title: "Buttons") {
                viewModel.openButtons()
            }
        }
        .padding()
    }
}
