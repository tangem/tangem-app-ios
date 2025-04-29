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

    func endEditing() {
        windows.first { $0.isKeyWindow }?.endEditing(true)
    }

    static var topViewController: UIViewController? {
        let mainWindow = UIApplication.shared.windows.last { $0 is MainWindow }
        return mainWindow?.topViewController
    }

    static func modalFromTop(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else { return }

        if top.isBeingDismissed || top.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                modalFromTop(vc, completion: completion)
            }
        } else {
            top.present(vc, animated: animated, completion: completion)
        }
    }
}
