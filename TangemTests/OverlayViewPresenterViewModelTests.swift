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

    @Test("Dismissing all takes down the whole stack at once, as the lock does")
    func dismissAllEmptiesTheStack() {
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
