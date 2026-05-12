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
            .navigation(item: $coordinator.tangemButtonV2DemoViewModel) {
                TangemButtonV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemBadgeDemoViewModel) {
                TangemBadgeDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemBadgeV2DemoViewModel) {
                TangemBadgeV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemCalloutDemoViewModel) {
                TangemCalloutDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemMainActionButtonDemoViewModel) {
                TangemMainActionButtonDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.notificationBannerDemoViewModel) {
                NotificationBannerDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemSegmentedPickerDemoViewModel) {
                TangemSegmentedPickerDemo(viewModel: $0)
            }
            .navigation(item: $coordinator.typographyDemoViewModel) {
                TypographyDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemTabsDemoViewModel) {
                TangemTabsDemo(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemSearchFieldDemoViewModel) {
                TangemSearchFieldDemo(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemDropDownDemoViewModel) {
                TangemDropDownDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemLoaderDemoViewModel) {
                TangemLoaderDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemTokenRowDemoViewModel) {
                TangemTokenRowDemoView(viewModel: $0)
            }
    }

    private var sheets: some View {
        EmptyView()
    }
}

struct DesignSystemDemoView: View {
    @ObservedObject var viewModel: DesignSystemDemoViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                MainButton(title: "TangemButton") {
                    viewModel.openTangemButtonDemo()
                }

                MainButton(title: "TangemButtonV2") {
                    viewModel.openTangemButtonV2Demo()
                }

                MainButton(title: "TangemBadge") {
                    viewModel.openTangemBadgeDemo()
                }

                MainButton(title: "TangemBadgeV2") {
                    viewModel.openTangemBadgeV2Demo()
                }

                MainButton(title: "TangemCallout") {
                    viewModel.openTangemCalloutDemo()
                }

                MainButton(title: "TangemSegmentedPicker") {
                    viewModel.openTangemSegmentedPickerDemo()
                }

                MainButton(title: "TangemTabs") {
                    viewModel.openTangemTabsDemo()
                }

                MainButton(title: "TangemSearchField") {
                    viewModel.openTangemSearchFieldDemo()
                }

                MainButton(title: "MainActionButton") {
                    viewModel.openTangemMainActionButtonDemo()
                }

                MainButton(title: "NotificationBanner") {
                    viewModel.openNotificationBannerDemo()
                }

                MainButton(title: "TangemDropDown") {
                    viewModel.openTangemDropDownDemo()
                }

                MainButton(title: "TangemLoader") {
                    viewModel.openTangemLoaderDemo()
                }

                MainButton(title: "TangemTokenRow") {
                    viewModel.openTangemTokenRowDemo()
                }

                MainButton(title: "Typography") {
                    viewModel.openTypographyDemo()
                }
            }
            .padding()
        }
        .navigationBarTitle(Text("Design System Demo"))
    }
}
