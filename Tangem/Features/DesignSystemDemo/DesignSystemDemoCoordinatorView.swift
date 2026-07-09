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
            .navigation(item: $coordinator.tangemCheckboxV2DemoViewModel) {
                TangemCheckboxV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemCheckmarkV2DemoViewModel) {
                TangemCheckmarkV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemBadgeDemoViewModel) {
                TangemBadgeDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemBadgeV2DemoViewModel) {
                TangemBadgeV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemMessageBannerDemoViewModel) {
                TangemMessageBannerDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemRowDemoViewModel) {
                TangemRowDemoView(viewModel: $0)
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
            .navigation(item: $coordinator.typographyV2DemoViewModel) {
                TypographyV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemTabsDemoViewModel) {
                TangemTabsDemo(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemSearchFieldDemoViewModel) {
                TangemSearchFieldDemo(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemSearchDemoViewModel) {
                TangemSearchDemoView(viewModel: $0)
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
            .navigation(item: $coordinator.tangemSnackbarDemoViewModel) {
                TangemSnackbarDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemShimmerDemoViewModel) {
                TangemShimmerDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.glowRingDemoViewModel, destination: GlowRingDemoView.init)
    }
}

struct DesignSystemDemoView: View {
    @ObservedObject var viewModel: DesignSystemDemoViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                section(title: "Design System V2") {
                    MainButton(title: "TangemButtonV2") {
                        viewModel.openTangemButtonV2Demo()
                    }

                    MainButton(title: "TangemCheckmarkV2") {
                        viewModel.openTangemCheckmarkV2Demo()
                    }

                    MainButton(title: "TangemBadgeV2") {
                        viewModel.openTangemBadgeV2Demo()
                    }

                    MainButton(title: "TangemMessageBanner") {
                        viewModel.openTangemMessageBannerDemo()
                    }

                    MainButton(title: "TangemCheckboxV2") {
                        viewModel.openTangemCheckboxV2Demo()
                    }

                    MainButton(title: "TangemRow") {
                        viewModel.openTangemRowDemo()
                    }

                    MainButton(title: "TangemLoader") {
                        viewModel.openTangemLoaderDemo()
                    }

                    MainButton(title: "TangemShimmer") {
                        viewModel.openTangemShimmerDemo()
                    }

                    MainButton(title: "GlowRing") {
                        viewModel.openGlowRingDemo()
                    }

                    MainButton(title: "TangemSearch") {
                        viewModel.openTangemSearchDemo()
                    }

                    MainButton(title: "Typography V2") {
                        viewModel.openTypographyV2Demo()
                    }
                }

                section(title: "Legacy") {
                    MainButton(title: "TangemButton") {
                        viewModel.openTangemButtonDemo()
                    }

                    MainButton(title: "TangemBadge") {
                        viewModel.openTangemBadgeDemo()
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

                    MainButton(title: "TangemTokenRow") {
                        viewModel.openTangemTokenRowDemo()
                    }

                    MainButton(title: "TangemSnackbar") {
                        viewModel.openTangemSnackbarDemo()
                    }

                    MainButton(title: "Typography") {
                        viewModel.openTypographyDemo()
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle(Text("Design System Demo"))
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)
            content()
        }
    }
}
