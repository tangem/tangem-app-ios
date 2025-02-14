//
//  UIApplication+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        _keyWindow?.endEditing(true)
    }
}

extension UIApplication {
    private var _keyWindow: UIWindow? {
        activeScene?
            .windows
            .filter { $0 is MainWindow }
            .first
    }

    static var keyWindow: UIWindow? {
        UIApplication.shared._keyWindow
    }

    private var activeScene: UIWindowScene? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first
    }

    static var activeScene: UIWindowScene? {
        UIApplication.shared.activeScene
    }

    static var topViewController: UIViewController? {
        return keyWindow?.topViewController
    }

    static func modalFromTop(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else { return }

        if top.isBeingDismissed || top.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                modalFromTop(vc)
            }
        } else {
            top.present(vc, animated: animated, completion: completion)
        }
    }

    static func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    // withTransaction not working with iOS16, UIView.performWithoutAnimations block not working
    static func performWithoutAnimations(_ block: () -> Void) {
        UIView.setAnimationsEnabled(false)

        block()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.setAnimationsEnabled(true)
        }
    }
}
