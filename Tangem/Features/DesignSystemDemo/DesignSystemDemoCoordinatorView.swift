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
            .navigation(item: $coordinator.tabNavigationDemoViewModel) {
                TabNavigationDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemTopNavigationDemoViewModel) {
                TangemTopNavigationDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemFadeDemoViewModel) {
                TangemFadeDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tangemMessageBubbleDemoViewModel) {
                TangemMessageBubbleDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tokenIconV2DemoViewModel) {
                TokenIconV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.tokenRowV2DemoViewModel) {
                TokenRowV2DemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.utilGraphDemoViewModel) {
                UtilGraphDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.utilPriceChangeDemoViewModel) {
                UtilPriceChangeDemoView(viewModel: $0)
            }
            .navigation(item: $coordinator.utilBalanceDemoViewModel) {
                UtilBalanceDemoView(viewModel: $0)
            }
    }
}

struct DesignSystemDemoView: View {
    @ObservedObject var viewModel: DesignSystemDemoViewModel

    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                let visibleSections = filteredSections

                if visibleSections.isEmpty {
                    Text("Nothing found")
                        .font(.headline)
                        .padding(.top, 32)
                } else {
                    ForEach(visibleSections) { section in
                        sectionView(section)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle(Text("Design System Demo"))
        .tangemSearchable(text: $searchText, prompt: "Search components", placement: .bottom)
    }

    private func sectionView(_ section: DemoSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(section.items) { item in
                MainButton(title: item.title, action: item.open)
            }
        }
    }

    private var filteredSections: [DemoSection] {
        guard !searchText.isEmpty else {
            return sections
        }

        return sections.compactMap { section in
            let items = section.items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            return items.isEmpty ? nil : DemoSection(title: section.title, items: items)
        }
    }

    private var sections: [DemoSection] {
        [
            DemoSection(title: "Design System V2", items: designSystemV2Items),
            DemoSection(title: "Legacy", items: legacyItems),
        ]
    }

    private var designSystemV2Items: [DemoItem] {
        [
            DemoItem(title: "Button", open: viewModel.openTangemButtonV2Demo),
            DemoItem(title: "Checkmark", open: viewModel.openTangemCheckmarkV2Demo),
            DemoItem(title: "Badge", open: viewModel.openTangemBadgeV2Demo),
            DemoItem(title: "MessageBanner", open: viewModel.openTangemMessageBannerDemo),
            DemoItem(title: "MessageBubble", open: viewModel.openTangemMessageBubbleDemo),
            DemoItem(title: "Checkbox", open: viewModel.openTangemCheckboxV2Demo),
            DemoItem(title: "Row", open: viewModel.openTangemRowDemo),
            DemoItem(title: "Loader", open: viewModel.openTangemLoaderDemo),
            DemoItem(title: "Shimmer", open: viewModel.openTangemShimmerDemo),
            DemoItem(title: "GlowRing", open: viewModel.openGlowRingDemo),
            DemoItem(title: "Fade", open: viewModel.openTangemFadeDemo),
            DemoItem(title: "TokenIconV2", open: viewModel.openTokenIconV2Demo),
            DemoItem(title: "TokenRow", open: viewModel.openTokenRowV2Demo),
            DemoItem(title: "UtilGraph", open: viewModel.openUtilGraphDemo),
            DemoItem(title: "UtilPriceChange", open: viewModel.openUtilPriceChangeDemo),
            DemoItem(title: "UtilBalance", open: viewModel.openUtilBalanceDemo),
            DemoItem(title: "Search", open: viewModel.openTangemSearchDemo),
            DemoItem(title: "Typography V2", open: viewModel.openTypographyV2Demo),
            DemoItem(title: "TabNavigation", open: viewModel.openTabNavigationDemo),
            DemoItem(title: "TopNavigation", open: viewModel.openTangemTopNavigationDemo),
        ]
    }

    private var legacyItems: [DemoItem] {
        [
            DemoItem(title: "TangemButton", open: viewModel.openTangemButtonDemo),
            DemoItem(title: "TangemBadge", open: viewModel.openTangemBadgeDemo),
            DemoItem(title: "TangemCallout", open: viewModel.openTangemCalloutDemo),
            DemoItem(title: "TangemSegmentedPicker", open: viewModel.openTangemSegmentedPickerDemo),
            DemoItem(title: "TangemTabs", open: viewModel.openTangemTabsDemo),
            DemoItem(title: "TangemSearchField", open: viewModel.openTangemSearchFieldDemo),
            DemoItem(title: "MainActionButton", open: viewModel.openTangemMainActionButtonDemo),
            DemoItem(title: "NotificationBanner", open: viewModel.openNotificationBannerDemo),
            DemoItem(title: "TangemDropDown", open: viewModel.openTangemDropDownDemo),
            DemoItem(title: "TangemTokenRow", open: viewModel.openTangemTokenRowDemo),
            DemoItem(title: "TangemSnackbar", open: viewModel.openTangemSnackbarDemo),
            DemoItem(title: "Typography", open: viewModel.openTypographyDemo),
        ]
    }
}

private extension DesignSystemDemoView {
    struct DemoItem: Identifiable {
        let title: String
        let open: () -> Void

        var id: String { title }
    }

    struct DemoSection: Identifiable {
        let title: String
        let items: [DemoItem]

        var id: String { title }
    }
}
