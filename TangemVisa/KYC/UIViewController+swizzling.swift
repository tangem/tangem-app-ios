//
//  UIViewController+swizzling.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import IdensicMobileSDK
import SwiftUI

extension UIViewController {
    static func toggleKYCSDKControllersSwizzling() {
        toggleSwizzling(
            originalSelector: #selector(UIViewController.present(_:animated:completion:)),
            swizzledSelector: #selector(UIViewController.swizzled_present(_:animated:completion:))
        )
        toggleSwizzling(
            originalSelector: #selector(UIViewController.viewWillLayoutSubviews),
            swizzledSelector: #selector(UIViewController.swizzled_viewWillLayoutSubviews)
        )
    }
}

private extension UIViewController {
    var isKYCSDKController: Bool {
        Bundle(for: type(of: self)).bundleIdentifier == Bundle(for: SNSMobileSDK.self).bundleIdentifier
    }

    static func toggleSwizzling(
        originalSelector: Selector,
        swizzledSelector: Selector
    ) {
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector)
        else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc
    func swizzled_viewWillLayoutSubviews() {
        swizzled_viewWillLayoutSubviews()

        guard isKYCSDKController,
              let navigationController,
              navigationController.modalPresentationStyle != .formSheet
        else {
            return
        }

        navigationController.isNavigationBarHidden = true
    }

    @objc
    func swizzled_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        let modifiedViewControllerToPresent: UIViewController
        defer {
            swizzled_present(modifiedViewControllerToPresent, animated: flag, completion: completion)
        }

        // Skip any changes made to viewControllerToPresent if:
        // 1. There is no shared KYCService set
        // 2. viewControllerToPresent is alert
        // 3. viewControllerToPresent won't be shown as a full screen
        guard let service = KYCService.shared,
              !(viewControllerToPresent is UIAlertController),
              [.fullScreen, .overFullScreen].contains(viewControllerToPresent.modalPresentationStyle)
        else {
            modifiedViewControllerToPresent = viewControllerToPresent
            return
        }

        let hostingController = UIHostingController(
            rootView: VStack(spacing: .zero) {
                KYCHeaderView(
                    stepPublisher: service.kycStepPublisher,
                    back: viewControllerToPresent.invokeRightBarButtonAction,
                    close: service.dismiss
                )
                UIViewControllerWrapper(controller: viewControllerToPresent)
            }
        )
        hostingController.modalTransitionStyle = viewControllerToPresent.modalTransitionStyle
        // Override .fullScreen to .overFullScreen to prevent gesture issues
        hostingController.modalPresentationStyle = .overFullScreen
        modifiedViewControllerToPresent = hostingController
    }
}

private extension UIViewController {
    func invokeRightBarButtonAction() {
        guard let rightBarButton = (self as? UINavigationController)?.topViewController?.navigationItem.rightBarButtonItem,
              let target = rightBarButton.target,
              let action = rightBarButton.action
        else {
            return
        }

        _ = target.perform(action, with: rightBarButton)
    }
}

private struct UIViewControllerWrapper: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
