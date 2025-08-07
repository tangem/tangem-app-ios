//
//  UIViewController+swizzling.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#if ALPHA || BETA || DEBUG
import SwiftUI
import IdensicMobileSDK
import TangemAssets

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

private extension UIViewController {
    // [REDACTED_TODO_COMMENT]
    // Current texts are just placeholders
    var backButtonTitle: String {
        "Back"
    }

    var closeButtonTitle: String {
        "Close"
    }

    func kycScreenInfo() -> (title: String, isInitial: Bool) {
        let title: String
        var isInitial = false

        switch String(describing: type(of: self)) {
        case "AgreementViewController":
            title = "Country of residence"
            isInitial = true

        case "SNSStatusVC":
            title = "Account verification"
            isInitial = true

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
            title = ""
        }

        return (title, isInitial)
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

        guard let service = KYCService.shared,
              let navigationController = self as? UINavigationController ?? navigationController,
              navigationController.modalPresentationStyle != .formSheet
        else {
            return
        }

        let color = UIColor(Colors.Text.primary1)
        let titleFont = UIFonts.Bold.headline

        // By default there is a close button at the right side of nav bar,
        // but according to design it should be placed differently.
        // Calling setLeftBarButton results in losing button's click handler
        navigationController.navigationBar.semanticContentAttribute = .forceRightToLeft
        navigationController.navigationBar.titleTextAttributes = [
            .font: titleFont,
            .foregroundColor: color,
        ]

        let (title, isInitialScreen) = kycScreenInfo()
        self.title = title

        guard let rightBarButtonItem = navigationItem.rightBarButtonItem else {
            return
        }

        rightBarButtonItem.title = isInitialScreen ? closeButtonTitle : backButtonTitle
        rightBarButtonItem.image = nil
        rightBarButtonItem.customView = nil
        rightBarButtonItem.style = .plain
        rightBarButtonItem.tintColor = color

        if !isInitialScreen {
            let closeButton = UIBarButtonItem(
                title: closeButtonTitle,
                style: .plain,
                target: service,
                action: #selector(KYCService.dismiss)
            )
            closeButton.tintColor = color
            navigationItem.setLeftBarButton(closeButton, animated: false)
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
        guard KYCService.shared != nil,
              !(viewControllerToPresent is UIAlertController),
              [.fullScreen, .overFullScreen].contains(viewControllerToPresent.modalPresentationStyle)
        else {
            modifiedViewControllerToPresent = viewControllerToPresent
            return
        }

        modifiedViewControllerToPresent = viewControllerToPresent
        modifiedViewControllerToPresent.modalPresentationStyle = .overFullScreen
    }
}
#endif // ALPHA || BETA || DEBUG
