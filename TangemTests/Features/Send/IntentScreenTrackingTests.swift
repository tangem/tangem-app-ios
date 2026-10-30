//
//  IntentScreenTrackingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("Intent screen tracking")
struct IntentScreenTrackingTests {
    @Test("An intent without an open Send or a sheet isn't on screen")
    func intentWithoutScreen() {
        #expect(!Self.isOnScreen(presentedOverlayId: nil) { _ in false })
    }

    @Test("An intent is on screen while the presenter shows its sheet or holds it in the queue")
    func presentedSheet() {
        #expect(Self.isOnScreen(presentedOverlayId: nil) { $0 == Self.intentID })
    }

    @Test("Another sheet on screen doesn't count as the intent's own")
    func anotherSheet() {
        #expect(!Self.isOnScreen(presentedOverlayId: nil) { $0 == "another-sheet" })
    }

    @Test("An open Send of the intent is on screen without a floating sheet")
    func openSend() {
        #expect(Self.isOnScreen(presentedOverlayId: Self.intentID) { _ in false })
    }

    @Test("Another screen shown over the app doesn't count as the intent's Send")
    func anotherOverlay() {
        #expect(!Self.isOnScreen(presentedOverlayId: "another-overlay") { _ in false })
    }

    private static let intentID = "0b0c5f3e-6a2d-4c55-9a8e-1f2d3c4b5a69"

    private static func isOnScreen(presentedOverlayId: String?, containsSheet: (_ id: String) -> Bool) -> Bool {
        SendIntentHandler.isOnScreen(intentID: intentID, presentedOverlayId: presentedOverlayId, containsSheet: containsSheet)
    }
}
