//
//  FeedPopGestureEnabler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct FeedPopGestureEnabler: UIViewControllerRepresentable {
    var prioritizesNavigation = false

    func makeUIViewController(context: Context) -> FeedPopGestureController {
        let controller = FeedPopGestureController()
        controller.prioritizesNavigation = prioritizesNavigation
        return controller
    }

    func updateUIViewController(_ controller: FeedPopGestureController, context: Context) {}
}

final class FeedPopGestureController: UIViewController, UIGestureRecognizerDelegate {
    var prioritizesNavigation = false

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        attachToPopGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        attachToPopGesture()
    }

    private func attachToPopGesture() {
        guard let recognizer = navigationController?.interactivePopGestureRecognizer else { return }

        recognizer.delegate = self
        recognizer.isEnabled = true

        if prioritizesNavigation, let contentView = parent?.view {
            prioritize(recognizer, in: contentView)
        }
    }

    /// Paging must yield to the navigation gesture that starts at the screen edge. Vertical scrolling is left alone:
    /// making it wait for the edge gesture to fail delays every swipe that starts near the leading edge.
    private func prioritize(_ recognizer: UIGestureRecognizer, in view: UIView) {
        if let scrollView = view as? UIScrollView, scrollView.isPagingEnabled {
            scrollView.panGestureRecognizer.require(toFail: recognizer)
        }

        for subview in view.subviews {
            prioritize(recognizer, in: subview)
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else { return false }

        return navigationController.viewControllers.count > 1 && navigationController.transitionCoordinator == nil
    }
}
