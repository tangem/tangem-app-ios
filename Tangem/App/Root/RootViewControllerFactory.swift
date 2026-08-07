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

        return hasHomeScreenIndicator
            ? Constants.notchDevicesOverlayCollapsedHeight
            : Constants.notchlessDevicesOverlayCollapsedHeight
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
        fileprivate static let notchDevicesOverlayCollapsedHeight: CGFloat = 108.0
        /// Based on Figma mockups.
        fileprivate static let notchlessDevicesOverlayCollapsedHeight: CGFloat = 90.0
        static let notchDevicesOverlayCornerRadius = 24.0
        static let notchlessDevicesOverlayCornerRadius = 16.0
    }
}
