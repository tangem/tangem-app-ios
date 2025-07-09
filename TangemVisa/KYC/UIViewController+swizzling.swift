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
            originalSelector: #selector(UIViewController.viewWillAppear),
            swizzledSelector: #selector(UIViewController.swizzled_viewWillAppear)
        )
    }
}

private let headerTag = 0xDEADBEEF

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
    func swizzled_viewWillAppear() {
        swizzled_viewWillAppear()
        
        guard isKYCSDKController,
              let navigationController,
              navigationController.modalPresentationStyle != .formSheet,
              let service = KYCService.shared
        else {
            return
        }
        
        let className = String(describing: type(of: self))

        var isInitialScreen = false
        switch className {
        case "AgreementViewController":
            title = "Country of residence"
            isInitialScreen = true

        case "SNSStatusVC":
            title = "Account verification"
            isInitialScreen = true

        case "QuestionnaireViewController":
            title = "Personal information"

        case "SNSDocTypePickerVC":
            title = "Identity document"

        case "SNSCameraVC":
            title = "Upload document"

        case "SNSPreviewVC":
            title = "Upload document"

        case "SNSFaceScanVC":
            title = "Liveness check"

        default:
            break
        }

        navigationController.navigationBar.semanticContentAttribute = .forceRightToLeft
        if let rightBarButtonItem = navigationItem.rightBarButtonItem {
            if isInitialScreen {
                let backButton = UIBarButtonItem(
                    title: "Close",
                    style: .plain,
                    target: rightBarButtonItem.target,
                    action: rightBarButtonItem.action
                )
                backButton.tintColor = UIColor(hex: "#1E1E1E")
                navigationItem.setRightBarButton(backButton, animated: false)
            } else {
                let backButton = UIBarButtonItem(
                    title: "Back",
                    style: .plain,
                    target: rightBarButtonItem.target,
                    action: rightBarButtonItem.action
                )
                backButton.tintColor = UIColor(hex: "#1E1E1E")
                navigationItem.setRightBarButton(backButton, animated: false)

                let closeButton = UIBarButtonItem(
                    title: "Close",
                    style: .plain,
                    target: service,
                    action: #selector(KYCService.dismiss)
                )
                closeButton.tintColor = UIColor(hex: "#1E1E1E")
                navigationItem.setLeftBarButton(closeButton, animated: false)
            }
        }
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

        modifiedViewControllerToPresent = viewControllerToPresent
        modifiedViewControllerToPresent.modalPresentationStyle = .overFullScreen

//        let hostingController = UIHostingController(
//            rootView: VStack(spacing: .zero) {
//                KYCHeaderView(
//                    stepPublisher: service.kycStepPublisher,
//                    back: viewControllerToPresent.invokeRightBarButtonAction,
//                    close: service.dismiss
//                )
//                UIViewControllerWrapper(controller: viewControllerToPresent)
//            }
//        )
//        hostingController.modalTransitionStyle = viewControllerToPresent.modalTransitionStyle
//        // Override .fullScreen to .overFullScreen to prevent gesture issues
//        hostingController.modalPresentationStyle = .overFullScreen
//        modifiedViewControllerToPresent = hostingController
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

extension UINavigationBar {
    func hide(except tag: Int) {
        for subview in subviews {
            // 1) Always keep your overlay intact
            if subview.tag == tag { continue }

            // 2) Keep the bar’s background container
            let name = String(describing: type(of: subview))
            if name == "_UIBarBackground" { continue }

            // 3) Everything else (buttons, labels, chevrons) gets alpha = 0
            subview.alpha = 0
        }
    }
}
