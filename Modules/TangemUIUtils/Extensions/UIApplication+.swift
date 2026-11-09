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
        mainWindow?.safeAreaInsets ?? .zero
    }

    /// The window that hosts the app's root view hierarchy.
    /// If two `MainWindow`s briefly coexist (e.g. during a re-lock), the newest (i.e. the last) one is returned.
    static var mainWindow: UIWindow? {
        lastWindow(ofType: MainWindow.self)
    }

    /// The pass-through window above the main one that hosts floating sheets and toasts.
    static var overlayWindow: UIWindow? {
        lastWindow(ofType: PassThroughWindow.self)
    }

    func endEditing() {
        Self.applicationWindowScene?.keyWindow?.endEditing(true)
    }

    static var topViewController: UIViewController? {
        mainWindow?.topViewController
    }

    static func modalFromTop(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let top = topViewController else { return }

        if top.isBeingDismissed || top.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                modalFromTop(vc, animated: animated, completion: completion)
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
}

// MARK: - Private implementation

private extension UIApplication {
    static var windowScenes: [UIWindowScene] {
        shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
    }

    static var applicationWindowScene: UIWindowScene? {
        windowScenes
            .first { $0.session.role == .windowApplication }
    }

    static func lastWindow<Window: UIWindow>(ofType windowType: Window.Type) -> Window? {
        windowScenes
            .flatMap(\.windows)
            .compactMap { $0 as? Window }
            .last
    }
}
