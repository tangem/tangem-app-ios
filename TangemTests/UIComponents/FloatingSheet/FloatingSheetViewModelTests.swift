//
//  FloatingSheetViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI
import Testing
@testable import Tangem

@Suite("FloatingSheetViewModel")
@MainActor
struct FloatingSheetViewModelTests {
    @Test("A sheet queued behind another one stays held and isn't the active sheet")
    func queuedSheetIsHeld() {
        let sut = FloatingSheetViewModel()
        let visibleSheet = SheetStub()
        weak var queuedSheet: SheetStub?

        sut.enqueue(sheet: visibleSheet)

        do {
            let sheet = SheetStub()
            queuedSheet = sheet
            sut.enqueue(sheet: sheet)
        }

        #expect(queuedSheet != nil)
        #expect(sut.activeSheet?.id == visibleSheet.id)
    }

    @Test("A sheet in a paused queue stays held, and is released once all sheets are removed")
    func pausedSheetIsHeldUntilRemoved() {
        let sut = FloatingSheetViewModel()
        weak var pausedSheet: SheetStub?

        do {
            let sheet = SheetStub()
            pausedSheet = sheet
            sut.enqueue(sheet: sheet)
        }

        #expect(sut.activeSheet?.id == pausedSheet?.id)

        sut.pauseSheetsDisplaying()

        #expect(pausedSheet != nil)
        #expect(sut.activeSheet == nil)

        sut.removeAllSheets()

        #expect(pausedSheet == nil)
    }

    @Test("Removing the active sheet by its id shows the next queued one")
    func removingActiveSheetById() {
        let sut = FloatingSheetViewModel()
        let activeSheet = SheetStub()
        let queuedSheet = SheetStub()

        sut.enqueue(sheet: activeSheet)
        sut.enqueue(sheet: queuedSheet)
        sut.removeSheet(withId: activeSheet.id)

        #expect(sut.activeSheet?.id == queuedSheet.id)
    }

    @Test("Removing a sheet held in a paused queue by its id drops only that sheet")
    func removingPausedSheetById() {
        let sut = FloatingSheetViewModel()
        let otherSheet = SheetStub()
        weak var removedSheet: SheetStub?

        do {
            let sheet = SheetStub()
            removedSheet = sheet
            sut.enqueue(sheet: sheet)
        }

        sut.enqueue(sheet: otherSheet)
        sut.pauseSheetsDisplaying()
        sut.removeSheet(withId: removedSheet?.id ?? "")
        sut.resumeSheetsDisplaying()

        #expect(removedSheet == nil)
        #expect(sut.activeSheet?.id == otherSheet.id)
    }

    @Test("Removing a sheet that isn't held leaves the presenter as it was")
    func removingUnknownSheetById() {
        let sut = FloatingSheetViewModel()
        let activeSheet = SheetStub()

        sut.enqueue(sheet: activeSheet)
        sut.removeSheet(withId: SheetStub().id)

        #expect(sut.activeSheet?.id == activeSheet.id)
    }

    @Test("An active, a queued and a paused sheet are all reported as contained")
    func containsHeldSheets() {
        let sut = FloatingSheetViewModel()
        let activeSheet = SheetStub()
        let queuedSheet = SheetStub()

        sut.enqueue(sheet: activeSheet)
        sut.enqueue(sheet: queuedSheet)

        #expect(sut.containsSheet(withId: activeSheet.id))
        #expect(sut.containsSheet(withId: queuedSheet.id))

        sut.pauseSheetsDisplaying()

        #expect(sut.containsSheet(withId: activeSheet.id))
        #expect(sut.containsSheet(withId: queuedSheet.id))
    }

    @Test("A sheet dismissed as the active one is no longer contained")
    func dismissedSheetIsNotContained() {
        let sut = FloatingSheetViewModel()
        let dismissedSheet = SheetStub()
        let nextSheet = SheetStub()

        sut.enqueue(sheet: dismissedSheet)
        sut.enqueue(sheet: nextSheet)
        sut.removeActiveSheet()

        #expect(!sut.containsSheet(withId: dismissedSheet.id))
        #expect(sut.containsSheet(withId: nextSheet.id))
    }

    @Test("A queued sheet's id is published only once the sheet becomes active")
    func queuedSheetIdIsPublishedWhenActive() {
        let sut = FloatingSheetViewModel()
        let visibleSheet = SheetStub()
        let queuedSheet = SheetStub()
        var publishedIds: [String?] = []
        let cancellable = sut.activeSheetIdPublisher.sink { publishedIds.append($0) }

        sut.enqueue(sheet: visibleSheet)
        sut.enqueue(sheet: queuedSheet)

        #expect(!publishedIds.contains(queuedSheet.id))

        sut.removeActiveSheet()

        #expect(publishedIds == [nil, visibleSheet.id, queuedSheet.id])
        cancellable.cancel()
    }
}

private final class SheetStub: FloatingSheetContentViewModel {}
