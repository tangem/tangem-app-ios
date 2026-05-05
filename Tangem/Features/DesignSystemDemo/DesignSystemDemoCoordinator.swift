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
    func openTangemBadgeDemo()
    func openTangemCalloutDemo()
    func openTangemTabsDemo()
    func openTangemMainActionButtonDemo()
    func openTangemSegmentedPickerDemo()
    func openTangemSearchFieldDemo()
    func openNotificationBannerDemo()
    func openTypographyDemo()
    func openTangemDropDownDemo()
    func openTangemLoaderDemo()
}

final class DesignSystemDemoCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: DesignSystemDemoViewModel?
    @Published var tangemButtonDemoViewModel: TangemButtonDemoViewModel?
    @Published var tangemBadgeDemoViewModel: TangemBadgeDemoViewModel?
    @Published var tangemCalloutDemoViewModel: TangemCalloutDemoViewModel?
    @Published var tangemTabsDemoViewModel: TangemTabsDemoModel?
    @Published var tangemMainActionButtonDemoViewModel: TangemMainActionButtonDemoViewModel?
    @Published var tangemSegmentedPickerDemoViewModel: TangemSegmentedPickerDemoModel?
    @Published var notificationBannerDemoViewModel: NotificationBannerDemoViewModel?
    @Published var typographyDemoViewModel: TypographyDemoViewModel?
    @Published var tangemSearchFieldDemoViewModel: TangemSearchFieldDemoViewModel?
    @Published var tangemDropDownDemoViewModel: TangemDropDownDemoViewModel?
    @Published var tangemLoaderDemoViewModel: TangemLoaderDemoViewModel?

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

    func openTangemBadgeDemo() {
        tangemBadgeDemoViewModel = .init()
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

    func openTangemSegmentedPickerDemo() {
        tangemSegmentedPickerDemoViewModel = .init()
    }

    func openTangemTabsDemo() {
        tangemTabsDemoViewModel = .init()
    }

    func openTangemSearchFieldDemo() {
        tangemSearchFieldDemoViewModel = .init()
    }

    func openTangemDropDownDemo() {
        tangemDropDownDemoViewModel = .init()
    }

    func openTangemLoaderDemo() {
        tangemLoaderDemoViewModel = .init()
    }
}

extension DesignSystemDemoCoordinator {
    struct Options {}
    typealias DismissOptions = Void
}
