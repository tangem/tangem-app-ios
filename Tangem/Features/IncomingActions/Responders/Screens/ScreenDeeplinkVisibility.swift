//
//  ScreenDeeplinkVisibility.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import TangemUIUtils

/// Whether a screen that lives in the window's root hierarchy is what the user sees. A screen shows a deeplink in
/// its own hierarchy, so what it opens appears where the screen is — under whatever is presented over it. A screen
/// that isn't on top has no business claiming the link and leaves it to whoever shows it over.
@MainActor
enum ScreenDeeplinkVisibility {
    static func isWindowRootOnTop() -> Bool {
        guard let rootViewController = UIApplication.mainWindow?.rootViewController else {
            return false
        }

        guard let presented = rootViewController.presentedViewController else {
            return true
        }

        return isShtorkaPresented && presented.presentedViewController == nil
    }

    /// The shtorka is the one presentation its screens are still seen through: the main screen shows it over
    /// itself, and the feed opens a token screen inside it. It steps aside for anything shown over the app, so
    /// what is presented while it is up is the shtorka itself.
    private static var isShtorkaPresented: Bool {
        InjectedValues[\.mainBottomSheetUIManager].isShown
    }
}
