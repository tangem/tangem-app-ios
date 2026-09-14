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
    func makeUIViewController(context: Context) -> FeedPopGestureController {
        FeedPopGestureController()
    }

    func updateUIViewController(_ controller: FeedPopGestureController, context: Context) {}
}

final class FeedPopGestureController: UIViewController, UIGestureRecognizerDelegate {
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
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else { return false }

        return navigationController.viewControllers.count > 1 && navigationController.transitionCoordinator == nil
    }
}
