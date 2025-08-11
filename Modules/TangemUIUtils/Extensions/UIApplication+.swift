//
//  UIApplication+.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

public extension UIApplication {
    static var safeAreaInsets: UIEdgeInsets {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.safeAreaInsets ?? .zero
    }

    static var mainWindow: UIWindow? {
        UIApplication.shared.windows.last // { $0 is MainWindow }
    }

    func endEditing() {
        windows.first { $0.isKeyWindow }?.endEditing(true)
    }

    static var topViewController: UIViewController? {
        UIApplication.mainWindow?.topViewController
    }

    static func dismissTop(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else {
            assertionFailure("Top view controller not found")
            return
        }

        top.dismiss(animated: animated, completion: completion)
    }

    static func modalFromTop(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else {
            assertionFailure("Top view controller not found")
            return
        }

        if top.isBeingDismissed || top.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                modalFromTop(vc, completion: completion)
            }
        } else {
            top.present(vc, animated: animated, completion: completion)
        }
    }
}
