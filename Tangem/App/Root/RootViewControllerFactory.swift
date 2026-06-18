//
//  RootViewControllerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TangemUIUtils

struct RootViewControllerFactory {
    @Injected(\.overlayContentContainerInitializer) private var overlayContentContainer: OverlayContentContainerInitializable

    private var overlayCollapsedHeight: CGFloat {
        let hasHomeScreenIndicator = UIDevice.current.hasHomeScreenIndicator

        if FeatureProvider.isAvailable(.redesign) {
            return hasHomeScreenIndicator
                ? Constants.notchDevicesOverlayCollapsedHeight
                : Constants.notchlessDevicesOverlayCollapsedHeight
        } else {
            return hasHomeScreenIndicator
                ? Constants.notchDevicesOverlayCollapsedHeight + Constants.overlayCollapsedHeightAdjustment
                : Constants.notchlessDevicesOverlayCollapsedHeight + Constants.overlayCollapsedHeightAdjustment
        }
    }

    func makeRootViewController(for rootView: some View, coordinator: AppCoordinator, window: UIWindow) -> UIViewController {
        let overlayCornerRadius: CGFloat

        if UIDevice.current.hasHomeScreenIndicator {
            overlayCornerRadius = Constants.notchDevicesOverlayCornerRadius
        } else {
            overlayCornerRadius = Constants.notchlessDevicesOverlayCornerRadius
        }

        let rootView = rootView
            .environment(\.mainWindowSize, window.screen.bounds.size)

        let contentViewController = UIHostingController(rootView: rootView)

        let containerViewController = OverlayContentContainerViewController(
            contentViewController: contentViewController,
            contentExpandedVerticalOffset: UIApplication.safeAreaInsets.top,
            overlayCollapsedHeight: overlayCollapsedHeight,
            overlayCornerRadius: overlayCornerRadius
        )

        overlayContentContainer.set(containerViewController)

        return containerViewController
    }
}

// MARK: - Constants

extension RootViewControllerFactory {
    enum Constants {
        /// Based on Figma mockups.
        fileprivate static let notchDevicesOverlayCollapsedHeight: CGFloat = FeatureProvider.isAvailable(.redesign) ? 108.0 : 100.0
        /// Based on Figma mockups.
        fileprivate static let notchlessDevicesOverlayCollapsedHeight: CGFloat = FeatureProvider.isAvailable(.redesign) ? 90.0 : 86.0
        /// The height of `SwiftUI.TextField` used in the `CustomSearchBar` UI components differs from the mockups by this small margin.
        fileprivate static let overlayCollapsedHeightAdjustment = 4.0
        static let notchDevicesOverlayCornerRadius = 24.0
        static let notchlessDevicesOverlayCornerRadius = 16.0
    }
}
