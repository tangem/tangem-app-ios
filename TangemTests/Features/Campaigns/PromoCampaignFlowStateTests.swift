//
//  PromoCampaignFlowStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("PromoCampaignFlowState", .tags(.campaigns))
struct PromoCampaignFlowStateTests {
    // MARK: - Sheet

    @Test("An enqueued sheet the presenter still holds isn't stale")
    func aliveSheetIsNotStale() {
        let sut = makeEnqueuedState()

        #expect(!sut.isStale(isSheetAlive: true))
    }

    @Test("An enqueued sheet the presenter dropped makes the flow stale")
    func droppedSheetIsStale() {
        let sut = makeEnqueuedState()

        #expect(sut.isStale(isSheetAlive: false))
    }

    @Test("Nothing is stale before the sheet is enqueued or after it is closed")
    func staleness() {
        var sut = PromoCampaignFlowState()
        #expect(!sut.isStale(isSheetAlive: false))

        sut.enqueueSheet()
        _ = sut.closeSheet()

        #expect(!sut.isStale(isSheetAlive: false))
    }

    @Test("Closing acts only once, on the flow's own sheet")
    func closingIsIdempotent() {
        var notEnqueued = PromoCampaignFlowState()
        let closedBeforeEnqueue = notEnqueued.closeSheet()
        #expect(!closedBeforeEnqueue)

        var sut = makeEnqueuedState()
        let firstClose = sut.closeSheet()
        let secondClose = sut.closeSheet()

        #expect(firstClose)
        #expect(!secondClose)
    }

    // MARK: - Enrollment

    @Test("Enrollment starts once, only from the enqueued sheet")
    func enrollmentStartsOnce() {
        var notEnqueued = PromoCampaignFlowState()
        let didStartBeforeEnqueue = notEnqueued.startEnrollment()
        #expect(!didStartBeforeEnqueue)

        var sut = makeEnqueuedState()
        let didStart = sut.startEnrollment()
        let didStartAgain = sut.startEnrollment()

        #expect(didStart)
        #expect(!didStartAgain)
    }

    @Test("While enrolling, a dropped sheet doesn't make the flow stale")
    func droppedSheetWhileEnrollingIsNotStale() {
        var sut = makeEnqueuedState()
        _ = sut.startEnrollment()

        #expect(!sut.isStale(isSheetAlive: false))
    }

    @Test("The result removes the sheet only while the presenter still holds the flow's own sheet")
    func resultRemovesOnlyOwnSheet() {
        var alive = makeEnqueuedState()
        _ = alive.startEnrollment()
        let aliveOwnsSheet = alive.finishEnrollment(isSheetAlive: true)
        #expect(aliveOwnsSheet)
        #expect(!alive.isEnrolling)

        var dropped = makeEnqueuedState()
        _ = dropped.startEnrollment()
        let droppedOwnsSheet = dropped.finishEnrollment(isSheetAlive: false)
        #expect(!droppedOwnsSheet)

        var closed = makeEnqueuedState()
        _ = closed.startEnrollment()
        _ = closed.closeSheet()
        let closedOwnsSheet = closed.finishEnrollment(isSheetAlive: true)
        #expect(!closedOwnsSheet)
    }

    @Test("Finishing an enrollment that never started is ignored")
    func finishWithoutStartIsIgnored() {
        var sut = makeEnqueuedState()

        let ownsSheet = sut.finishEnrollment(isSheetAlive: true)

        #expect(!ownsSheet)
        #expect(sut.sheet == .enqueued)
    }

    // MARK: - Safari

    @Test("Safari doesn't open while enrolling, and enrollment doesn't start while Safari is open")
    func safariAndEnrollmentExcludeEachOther() {
        var enrolling = makeEnqueuedState()
        _ = enrolling.startEnrollment()
        let didOpenSafari = enrolling.openSafari()
        #expect(!didOpenSafari)

        var browsing = makeEnqueuedState()
        _ = browsing.openSafari()
        let didStartEnrollment = browsing.startEnrollment()
        #expect(!didStartEnrollment)
    }

    @Test("While Safari is open a dropped sheet waits for Safari to close")
    func droppedSheetDuringSafari() {
        var sut = makeEnqueuedState()
        _ = sut.openSafari()

        #expect(!sut.isStale(isSheetAlive: false))

        let shouldEndAfterSafari = sut.closeSafari(isSheetAlive: false)
        #expect(shouldEndAfterSafari)
        #expect(!sut.isSafariPresented)
    }

    @Test("After Safari the flow goes on while its sheet is held, and a second close is ignored")
    func safariClosedWithSheet() {
        var sut = makeEnqueuedState()
        _ = sut.openSafari()

        let shouldEnd = sut.closeSafari(isSheetAlive: true)
        let shouldEndAgain = sut.closeSafari(isSheetAlive: false)

        #expect(!shouldEnd)
        #expect(!shouldEndAgain)
        #expect(sut.sheet == .enqueued)
    }

    // MARK: - Finish

    @Test("The flow finishes once, and a second finish is ignored")
    func finishesOnce() {
        var sut = makeEnqueuedState()

        let didFinish = sut.finish()
        let didFinishAgain = sut.finish()

        #expect(didFinish)
        #expect(!didFinishAgain)
        #expect(sut.isFinished)
    }

    @Test("Sheets paused for the result are remembered until the flow finishes")
    func sheetsPausedForResult() {
        var sut = makeEnqueuedState()
        #expect(!sut.isSheetsDisplayingPausedForResult)

        sut.pauseSheetsForResult()
        _ = sut.finish()

        #expect(sut.isSheetsDisplayingPausedForResult)
    }

    // MARK: - Scanning and unlocking

    @Test("A result received outside card scanning and unlocking is shown right away")
    func resultShownRightAway() {
        var sut = makeEnqueuedState()

        let shownResult = sut.receiveResult(result)

        #expect(shownResult == result)
        #expect(sut.deferredResult == nil)
    }

    @Test("A result received while a card is scanned or a wallet unlocked waits for that to end")
    func resultDeferredDuringUnlock() {
        var sut = makeEnqueuedState()
        _ = sut.changeScanningOrUnlocking(isActive: true)

        let shownResult = sut.receiveResult(result)
        #expect(shownResult == nil)

        let releasedResult = sut.changeScanningOrUnlocking(isActive: false)
        #expect(releasedResult == result)
        #expect(sut.deferredResult == nil)
    }

    @Test("A result waiting for an unlock is dropped when the flow finishes")
    func deferredResultDroppedOnFinish() {
        var sut = makeEnqueuedState()
        _ = sut.changeScanningOrUnlocking(isActive: true)
        _ = sut.receiveResult(result)

        _ = sut.finish()
        let releasedResult = sut.changeScanningOrUnlocking(isActive: false)

        #expect(releasedResult == nil)
        #expect(sut.deferredResult == nil)
    }

    @Test("A result received after the flow finished is ignored")
    func resultIgnoredAfterFinish() {
        var sut = makeEnqueuedState()
        _ = sut.finish()

        let shownResult = sut.receiveResult(result)

        #expect(shownResult == nil)
    }
}

// MARK: - Helpers

private extension PromoCampaignFlowStateTests {
    var result: PromoCampaignFlowState.Result {
        PromoCampaignFlowState.Result(outcome: .failed, campaign: PromoCampaignFixtures.makeCampaign(id: 7))
    }

    func makeEnqueuedState() -> PromoCampaignFlowState {
        var state = PromoCampaignFlowState()
        state.enqueueSheet()
        return state
    }
}
