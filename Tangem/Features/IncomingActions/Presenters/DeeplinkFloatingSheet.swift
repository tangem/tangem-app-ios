//
//  DeeplinkFloatingSheet.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum DeeplinkFloatingSheet {
    /// Floating sheets live in a window above the one deeplink screens are shown in, so an active one would
    /// cover whatever a deeplink opens. Every responder that shows something else takes it away first.
    ///
    /// - Note: only when one is actually on screen — while the queue is paused, removing would silently drop
    ///   the sheet waiting at its head.
    static func dismissActive() {
        guard InjectedValues[\.floatingSheetPresentingStateProvider].hasPresentedSheet else {
            return
        }

        let presenter = InjectedValues[\.floatingSheetPresenter]

        // Synchronously when possible: the caller shows its screen right after, and a hop would leave the
        // sheet on top of it for a frame.
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                presenter.removeActiveSheet()
            }
        } else {
            Task { @MainActor in
                presenter.removeActiveSheet()
            }
        }
    }
}
