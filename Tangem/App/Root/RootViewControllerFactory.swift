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
            .mainWindowSize(initial: window.screen.bounds.size)

        if FeatureProvider.isAvailable(.newShtorkaEnabled) {
            return TraitStatusBarHostingController(rootView: rootView)
        }

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

// MARK: - TraitStatusBarHostingController

private final class TraitStatusBarHostingController<Content: View>: UIHostingController<Content> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
    }

    override var childForStatusBarStyle: UIViewController? {
        nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
}
