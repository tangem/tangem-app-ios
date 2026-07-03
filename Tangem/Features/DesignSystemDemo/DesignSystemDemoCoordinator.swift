//
//  DesignSystemDemoCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

protocol DesignSystemDemoRoutable: AnyObject {
    func openTangemButtonDemo()
    func openTangemButtonV2Demo()
    func openTangemBadgeDemo()
    func openTangemBadgeV2Demo()
    func openTangemMessageBannerDemo()
    func openTangemRowDemo()
    func openTangemCalloutDemo()
    func openTangemTabsDemo()
    func openTangemMainActionButtonDemo()
    func openTangemSegmentedPickerDemo()
    func openTangemSearchFieldDemo()
    func openTangemSearchDemo()
    func openNotificationBannerDemo()
    func openTypographyDemo()
    func openTypographyV2Demo()
    func openTangemDropDownDemo()
    func openTangemLoaderDemo()
    func openTangemTokenRowDemo()
    func openTangemSnackbarDemo()
    func openTangemShimmerDemo()
    func openGlowRingDemo()
}

final class DesignSystemDemoCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: DesignSystemDemoViewModel?
    @Published var tangemButtonDemoViewModel: TangemButtonDemoViewModel?
    @Published var tangemButtonV2DemoViewModel: TangemButtonV2DemoViewModel?
    @Published var tangemBadgeDemoViewModel: TangemBadgeDemoViewModel?
    @Published var tangemBadgeV2DemoViewModel: TangemBadgeV2DemoViewModel?
    @Published var tangemMessageBannerDemoViewModel: TangemMessageBannerDemoViewModel?
    @Published var tangemRowDemoViewModel: TangemRowDemoViewModel?
    @Published var tangemCalloutDemoViewModel: TangemCalloutDemoViewModel?
    @Published var tangemTabsDemoViewModel: TangemTabsDemoModel?
    @Published var tangemMainActionButtonDemoViewModel: TangemMainActionButtonDemoViewModel?
    @Published var tangemSegmentedPickerDemoViewModel: TangemSegmentedPickerDemoModel?
    @Published var notificationBannerDemoViewModel: NotificationBannerDemoViewModel?
    @Published var typographyDemoViewModel: TypographyDemoViewModel?
    @Published var typographyV2DemoViewModel: TypographyV2DemoViewModel?
    @Published var tangemSearchFieldDemoViewModel: TangemSearchFieldDemoViewModel?
    @Published var tangemSearchDemoViewModel: TangemSearchDemoViewModel?
    @Published var tangemDropDownDemoViewModel: TangemDropDownDemoViewModel?
    @Published var tangemLoaderDemoViewModel: TangemLoaderDemoViewModel?
    @Published var tangemTokenRowDemoViewModel: TangemTokenRowDemoViewModel?
    @Published var tangemSnackbarDemoViewModel: TangemSnackbarDemoViewModel?
    @Published var tangemShimmerDemoViewModel: TangemShimmerDemoViewModel?
    @Published var glowRingDemoViewModel: GlowRingDemoViewModel?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction

        rootViewModel = .init(coordinator: self)
    }

    func start(with options: Void) {}
}

extension DesignSystemDemoCoordinator: DesignSystemDemoRoutable {
    func openTangemButtonDemo() {
        tangemButtonDemoViewModel = .init()
    }

    func openTangemButtonV2Demo() {
        tangemButtonV2DemoViewModel = .init()
    }

    func openTangemBadgeDemo() {
        tangemBadgeDemoViewModel = .init()
    }

    func openTangemBadgeV2Demo() {
        tangemBadgeV2DemoViewModel = .init()
    }

    func openTangemMessageBannerDemo() {
        tangemMessageBannerDemoViewModel = .init()
    }

    func openTangemRowDemo() {
        tangemRowDemoViewModel = .init()
    }

    func openTangemCalloutDemo() {
        tangemCalloutDemoViewModel = .init()
    }

    func openTangemMainActionButtonDemo() {
        tangemMainActionButtonDemoViewModel = .init()
    }

    func openNotificationBannerDemo() {
        notificationBannerDemoViewModel = .init()
    }

    func openTypographyDemo() {
        typographyDemoViewModel = .init()
    }

    func openTypographyV2Demo() {
        typographyV2DemoViewModel = .init()
    }

    func openTangemSegmentedPickerDemo() {
        tangemSegmentedPickerDemoViewModel = .init()
    }

    func openTangemTabsDemo() {
        tangemTabsDemoViewModel = .init()
    }

    func openTangemSearchFieldDemo() {
        tangemSearchFieldDemoViewModel = .init()
    }

    func openTangemSearchDemo() {
        tangemSearchDemoViewModel = .init()
    }

    func openTangemDropDownDemo() {
        tangemDropDownDemoViewModel = .init()
    }

    func openTangemLoaderDemo() {
        tangemLoaderDemoViewModel = .init()
    }

    func openTangemTokenRowDemo() {
        tangemTokenRowDemoViewModel = .init()
    }

    func openTangemSnackbarDemo() {
        tangemSnackbarDemoViewModel = .init()
    }

    func openTangemShimmerDemo() {
        tangemShimmerDemoViewModel = .init()
    }

    func openGlowRingDemo() {
        glowRingDemoViewModel = .init()
    }
}

extension DesignSystemDemoCoordinator {
    struct Options {}
    typealias DismissOptions = Void
}
