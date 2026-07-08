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

    func openTangemButtonV2Demo() {
        coordinator?.openTangemButtonV2Demo()
    }

    func openTangemCheckboxV2Demo() {
        coordinator?.openTangemCheckboxV2Demo()
    }

    func openTangemBadgeDemo() {
        coordinator?.openTangemBadgeDemo()
    }

    func openTangemBadgeV2Demo() {
        coordinator?.openTangemBadgeV2Demo()
    }

    func openTangemMessageBannerDemo() {
        coordinator?.openTangemMessageBannerDemo()
    }

    func openTangemRowDemo() {
        coordinator?.openTangemRowDemo()
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

    func openTypographyV2Demo() {
        coordinator?.openTypographyV2Demo()
    }

    func openTangemSegmentedPickerDemo() {
        coordinator?.openTangemSegmentedPickerDemo()
    }

    func openTangemTabsDemo() {
        coordinator?.openTangemTabsDemo()
    }

    func openTangemSearchFieldDemo() {
        coordinator?.openTangemSearchFieldDemo()
    }

    func openTangemSearchDemo() {
        coordinator?.openTangemSearchDemo()
    }

    func openTangemDropDownDemo() {
        coordinator?.openTangemDropDownDemo()
    }

    func openTangemLoaderDemo() {
        coordinator?.openTangemLoaderDemo()
    }

    func openTangemTokenRowDemo() {
        coordinator?.openTangemTokenRowDemo()
    }

    func openTangemSnackbarDemo() {
        coordinator?.openTangemSnackbarDemo()
    }

    func openTangemShimmerDemo() {
        coordinator?.openTangemShimmerDemo()
    }

    func openGlowRingDemo() {
        coordinator?.openGlowRingDemo()
    }
}
