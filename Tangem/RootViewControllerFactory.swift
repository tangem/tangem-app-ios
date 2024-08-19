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

struct RootViewControllerFactory {
    func makeRootViewController(for rootView: some View, window: UIWindow) -> UIViewController {
        guard FeatureProvider.isAvailable(.markets) else {
            return UIHostingController(rootView: rootView)
        }

        let adapter = OverlayContentContainerViewControllerAdapter()

        let rootView = rootView
            .environment(\.overlayContentContainer, adapter)
            .environment(\.overlayContentStateObserver, adapter)
            .environment(\.overlayContentStateController, adapter)
            .environment(\.mainWindowSize, window.screen.bounds.size)

        let contentViewController = UIHostingController(rootView: rootView)

        // [REDACTED_TODO_COMMENT]
        let containerViewController = OverlayContentContainerViewController(
            contentViewController: contentViewController,
            overlayCollapsedHeight: 102.0, // [REDACTED_INFO]
            overlayExpandedVerticalOffset: 54.0, // [REDACTED_INFO]
            overlayCornerRadius: UIDevice.current.hasTopNotch ? 24.0 : 16.0
        )

        adapter.set(containerViewController)

        return containerViewController
    }
}
