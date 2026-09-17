//
//  MainShtorkaStateObjectTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
@testable import Tangem

/// The shtorka and a screen shown over the whole app share the root's one presentation slot, so the shtorka is
/// up exactly when the coordinator wants it shown and nothing is presented over the app.
@Suite("Main shtorka state", .serialized)
@MainActor
struct MainShtorkaStateObjectTests {
    @Test("Shown by the coordinator with nothing over the app, the shtorka is up")
    func shownWithoutOverlayIsPresented() async {
        await withCleanEnvironment { stateObject in
            InjectedValues[\.mainBottomSheetUIManager].show()

            #expect(await waitUntilConditionMet { stateObject.isPresented })
        }
    }

    @Test("The shtorka steps aside while an overlay is presented and comes back once it is gone")
    func stepsAsideForAnOverlay() async {
        await withCleanEnvironment { stateObject in
            InjectedValues[\.mainBottomSheetUIManager].show()
            #expect(await waitUntilConditionMet { stateObject.isPresented })

            InjectedValues[\.overlayViewPresenter].present(Self.overlay)
            #expect(await waitUntilConditionMet { !stateObject.isPresented })

            InjectedValues[\.overlayViewPresenter].dismiss()
            #expect(await waitUntilConditionMet { stateObject.isPresented })
        }
    }

    @Test("An overlay that was up before the coordinator asked for the shtorka keeps it down")
    func overlayUpBeforeShowKeepsItDown() async {
        await withCleanEnvironment { stateObject in
            InjectedValues[\.overlayViewPresenter].present(Self.overlay)
            InjectedValues[\.mainBottomSheetUIManager].show()

            try? await Task.sleep(nanoseconds: 100_000_000)
            #expect(!stateObject.isPresented)

            InjectedValues[\.overlayViewPresenter].dismiss()
            #expect(await waitUntilConditionMet { stateObject.isPresented })
        }
    }
}

// MARK: - Environment

private extension MainShtorkaStateObjectTests {
    static let overlay = OverlayView(id: "test-overlay", view: EmptyView(), style: .sheet)

    func withCleanEnvironment(_ body: (MainShtorkaStateObject) async -> Void) async {
        let manager = InjectedValues[\.mainBottomSheetUIManager]
        let presenter = InjectedValues[\.overlayViewPresenter]

        manager.hide(shouldUpdateFooterSnapshot: false)
        presenter.dismissAll()

        let stateObject = MainShtorkaStateObject()

        await body(stateObject)

        manager.hide(shouldUpdateFooterSnapshot: false)
        presenter.dismissAll()
    }
}
