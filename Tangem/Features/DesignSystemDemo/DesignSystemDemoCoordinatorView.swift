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
            .navigation(item: $coordinator.tangemButtonDemoViewModel) {
                TangemButtonDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemBadgeDemoViewModel) {
                TangemBadgeDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemMainActionButtonDemoViewModel) {
                TangemMainActionButtonDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.notificationBannerDemoViewModel) {
                NotificationBannerDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.typographyDemoViewModel) {
                TypographyDemoView(viewModel: $0)
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
            MainButton(title: "TangemButton") {
                viewModel.openTangemButtonDemo()
            }

            MainButton(title: "TangemBadge") {
                viewModel.openTangemBadgeDemo()
            }

            MainButton(title: "MainActionButton") {
                viewModel.openTangemMainActionButtonDemo()
            }

            MainButton(title: "NotificationBanner") {
                viewModel.openNotificationBannerDemo()
            }

            MainButton(title: "Typography") {
                viewModel.openTypographyDemo()
            }
        }
        .padding()
        .navigationBarTitle(Text("Design System Demo"))
    }
}
