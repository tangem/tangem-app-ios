//
//  OverlayViewPresenterViewModelTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Testing
@testable import Tangem

@Suite("Overlay view presenter")
@MainActor
struct OverlayViewPresenterViewModelTests {
    @Test("Presenting and dismissing one overlay leaves nothing presented")
    func presentThenDismiss() {
        let presenter = OverlayViewPresenterViewModel()

        presenter.present(Self.overlay(id: "one"))
        #expect(presenter.isPresenting)

        presenter.dismiss()
        #expect(!presenter.isPresenting)
    }

    @Test("The same overlay is not presented twice")
    func sameOverlayPresentedOnce() {
        let presenter = OverlayViewPresenterViewModel()

        presenter.present(Self.overlay(id: "one"))
        presenter.present(Self.overlay(id: "one"))
        presenter.dismiss()

        #expect(!presenter.isPresenting)
    }

    @Test("A newer overlay takes the place of the one presented")
    func newerOverlayReplacesPresented() {
        let presenter = OverlayViewPresenterViewModel()

        presenter.present(Self.overlay(id: "one"))
        presenter.present(Self.overlay(id: "two"))

        #expect(presenter.presentedOverlay?.id == "two")
    }

    @Test("Dismissing all takes down what is presented, as the lock does")
    func dismissAllTakesDownPresented() {
        let presenter = OverlayViewPresenterViewModel()

        presenter.present(Self.overlay(id: "one"))
        presenter.present(Self.overlay(id: "two"))
        presenter.dismissAll()

        #expect(!presenter.isPresenting)
    }
}

private extension OverlayViewPresenterViewModelTests {
    static func overlay(id: String) -> OverlayView {
        OverlayView(id: id, view: EmptyView(), style: .sheet)
    }
}
