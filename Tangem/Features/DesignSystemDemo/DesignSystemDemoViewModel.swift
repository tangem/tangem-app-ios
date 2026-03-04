//
//  DesignSystemDemoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

final class DesignSystemDemoViewModel: ObservableObject {
    weak var coordinator: DesignSystemDemoRoutable?

    init(coordinator: DesignSystemDemoRoutable) {
        self.coordinator = coordinator
    }

    func openTangemButtonDemo() {
        coordinator?.openTangemButtonDemo()
    }

    func openTangemBadgeDemo() {
        coordinator?.openTangemBadgeDemo()
    }

    func openTangemCalloutDemo() {
        coordinator?.openTangemCalloutDemo()
    }

    func openTangemMainActionButtonDemo() {
        coordinator?.openTangemMainActionButtonDemo()
    }

    func openNotificationBannerDemo() {
        coordinator?.openNotificationBannerDemo()
    }

    func openTypographyDemo() {
        coordinator?.openTypographyDemo()
    }
}
