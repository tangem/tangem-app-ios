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

/// App overlays are presented above the shtorka and must not dismiss it or its presented content.
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

    @Test("Presenting and dismissing an app overlay preserves the shtorka and its size")
    func overlayPreservesPresentation() async {
        await withCleanEnvironment { stateObject in
            InjectedValues[\.mainBottomSheetUIManager].show()
            #expect(await waitUntilConditionMet { stateObject.isPresented })
            stateObject.expand()

            InjectedValues[\.overlayViewPresenter].present(Self.overlay)
            try? await Task.sleep(nanoseconds: 100_000_000)
            #expect(stateObject.isPresented)
            #expect(stateObject.size == .full)

            InjectedValues[\.overlayViewPresenter].dismiss()
            try? await Task.sleep(nanoseconds: 100_000_000)
            #expect(stateObject.isPresented)
            #expect(stateObject.size == .full)
        }
    }

    @Test("The coordinator controls shtorka visibility while an overlay is up")
    func coordinatorControlsVisibilityWithOverlay() async {
        await withCleanEnvironment { stateObject in
            InjectedValues[\.overlayViewPresenter].present(Self.overlay)
            InjectedValues[\.mainBottomSheetUIManager].show()
            #expect(await waitUntilConditionMet { stateObject.isPresented })

            InjectedValues[\.mainBottomSheetUIManager].hide(shouldUpdateFooterSnapshot: false)
            #expect(await waitUntilConditionMet { !stateObject.isPresented })

            InjectedValues[\.mainBottomSheetUIManager].show()
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
