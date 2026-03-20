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
    func openTangemMainActionButtonDemo()
    func openNotificationBannerDemo()
    func openTypographyDemo()
}

final class DesignSystemDemoCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Published var rootViewModel: DesignSystemDemoViewModel?
    @Published var tangemButtonDemoViewModel: TangemButtonDemoViewModel?
    @Published var tangemBadgeDemoViewModel: TangemBadgeDemoViewModel?
    @Published var tangemCalloutDemoViewModel: TangemCalloutDemoViewModel?
    @Published var tangemMainActionButtonDemoViewModel: TangemMainActionButtonDemoViewModel?
    @Published var notificationBannerDemoViewModel: NotificationBannerDemoViewModel?
    @Published var typographyDemoViewModel: TypographyDemoViewModel?

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
}

extension DesignSystemDemoCoordinator {
    struct Options {}
    typealias DismissOptions = Void
}
