//
//  TopNavigationPopGestureEnabler.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct TopNavigationPopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TopNavigationPopGestureController {
        TopNavigationPopGestureController()
    }

    func updateUIViewController(_ controller: TopNavigationPopGestureController, context: Context) {}
}

final class TopNavigationPopGestureController: UIViewController, UIGestureRecognizerDelegate {
    private weak var popGestureRecognizer: UIGestureRecognizer?
    private weak var previousDelegate: UIGestureRecognizerDelegate?

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent == nil {
            releasePopGesture()
        } else {
            takeOverPopGesture()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        takeOverPopGesture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        releasePopGesture()
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else {
            return false
        }

        return navigationController.viewControllers.count > 1 && navigationController.transitionCoordinator == nil
    }

    private func takeOverPopGesture() {
        guard let recognizer = navigationController?.interactivePopGestureRecognizer, recognizer.delegate !== self else {
            return
        }

        previousDelegate = recognizer.delegate
        popGestureRecognizer = recognizer
        recognizer.delegate = self
        recognizer.isEnabled = true
    }

    private func releasePopGesture() {
        guard let recognizer = popGestureRecognizer, recognizer.delegate === self else {
            return
        }

        recognizer.delegate = previousDelegate
        popGestureRecognizer = nil
    }
}
