//
//  UIViewController+swizzling.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import IdensicMobileSDK
import TangemAssets
import UIKit

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

        // By default there is a close button at the right side of nav bar,
        // but according to design it should be placed differently.
        // Calling setLeftBarButton results in losing button's click handler
        navigationController.navigationBar.semanticContentAttribute = .forceRightToLeft

        guard let rightBarButtonItem = navigationItem.rightBarButtonItem else {
            return
        }

        if isInitialScreen {
            rightBarButtonItem.isHidden = true
        } else {
            rightBarButtonItem.image = backIcon
        }

        let closeButton = UIBarButtonItem(
            image: closeIcon,
            style: .plain,
            target: service,
            action: #selector(KYCService.dismiss)
        )
        navigationItem.setLeftBarButton(closeButton, animated: false)
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

    var isInitialScreen: Bool {
        switch String(describing: type(of: self)) {
        case "AgreementViewController",
             "SNSStatusVC":
            true
        default:
            false
        }
    }

    var backIcon: UIImage {
        Assets.Glyphs.chevron20LeftButtonNew.uiImage
            .withCircleBackground(
                circleSize: 36,
                iconSize: 20,
                circleColor: .buttonSecondary,
                iconColor: .iconInformative
            )
    }

    var closeIcon: UIImage {
        Assets.Glyphs.cross20ButtonNew.uiImage
            .withCircleBackground(
                circleSize: 36,
                iconSize: 20,
                circleColor: .buttonSecondary,
                iconColor: .iconInformative
            )
    }
}

private extension UIImage {
    func withCircleBackground(
        circleSize: CGFloat,
        iconSize: CGFloat,
        circleColor: UIColor,
        iconColor: UIColor
    ) -> UIImage {
        let canvasSize = CGSize(width: circleSize, height: circleSize)
        let iconInset = (circleSize - iconSize) / 2
        let iconFrame = CGRect(x: iconInset, y: iconInset, width: iconSize, height: iconSize)
        let imageAsset = UIImageAsset()

        for style in [UIUserInterfaceStyle.light, .dark] {
            let appearance = UITraitCollection(userInterfaceStyle: style)

            let variant = UIGraphicsImageRenderer(size: canvasSize)
                .image { context in
                    circleColor.resolvedColor(with: appearance).setFill()
                    context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: canvasSize))

                    let tintedIcon = self.withRenderingMode(.alwaysOriginal)
                        .withTintColor(iconColor.resolvedColor(with: appearance), renderingMode: .alwaysOriginal)
                    tintedIcon.draw(in: iconFrame)
                }
                .withRenderingMode(.alwaysOriginal)

            let variantTraits = UITraitCollection(traitsFrom: [
                appearance,
                UITraitCollection(displayScale: variant.scale),
            ])
            imageAsset.register(variant, with: variantTraits)
        }

        return imageAsset.image(with: .current)
    }
}
