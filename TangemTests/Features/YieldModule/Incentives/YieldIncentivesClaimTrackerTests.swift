//
//  YieldIncentivesClaimTrackerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("YieldIncentivesClaimTracker", .timeLimit(.minutes(1)))
struct YieldIncentivesClaimTrackerTests {
    @Test("Only one claim may be in flight")
    func onlyOneClaimMayBeInFlight() async {
        let sut = YieldIncentivesClaimTracker()

        #expect(await sut.beginClaim())
        #expect(await !sut.beginClaim())
        #expect(await sut.isClaimInFlight)
    }

    @Test("A claim released before the network frees the guard")
    func releasedClaimFreesTheGuard() async {
        let sut = YieldIncentivesClaimTracker()

        _ = await sut.beginClaim()
        await sut.releaseClaim()

        #expect(await !sut.isClaimInFlight)
        #expect(await sut.beginClaim())
    }

    @Test("A submitted claim is announced at once and settled once the hash clears")
    func submittedClaimSettlesOnClearance() async {
        let sut = YieldIncentivesClaimTracker()
        let recorder = ClaimEventRecorder(tracker: sut)
        let clearanceCalls = OSAllocatedUnfairLock(initialState: 0)

        _ = await sut.beginClaim()
        await sut.claimSubmitted {
            clearanceCalls.withLock { $0 += 1 }
            return true
        }

        await recorder.waitForSettlement()

        #expect(recorder.events == [.submitted, .settled])
        #expect(clearanceCalls.withLock { $0 } == 1)
        #expect(await !sut.isClaimInFlight)
    }

    @Test("A hash that never clears gives up after the settlement rounds")
    func unclearedHashGivesUpAfterTheRounds() async {
        let sut = YieldIncentivesClaimTracker()
        let recorder = ClaimEventRecorder(tracker: sut)
        let clearanceCalls = OSAllocatedUnfairLock(initialState: 0)

        _ = await sut.beginClaim()
        await sut.claimSubmitted {
            clearanceCalls.withLock { $0 += 1 }
            return false
        }

        await recorder.waitForSettlement()

        #expect(clearanceCalls.withLock { $0 } == YieldIncentivesClaimTracker.Constants.settlementRounds)
        #expect(await !sut.isClaimInFlight)
    }

    @Test("The guard outlives the submission and is held until the claim settles")
    func theGuardIsHeldUntilSettlement() async {
        let sut = YieldIncentivesClaimTracker()
        let recorder = ClaimEventRecorder(tracker: sut)
        let gate = YieldAsyncGate()

        _ = await sut.beginClaim()
        await sut.claimSubmitted {
            await gate.wait()
            return true
        }

        await gate.waitForArrival()

        #expect(await sut.isClaimInFlight)
        #expect(await !sut.beginClaim())
        #expect(recorder.events == [.submitted])

        gate.open()
        await recorder.waitForSettlement()

        #expect(await sut.beginClaim())
    }

    @Test("Trackers are shared per chain and owner, and never across them")
    func trackersAreSharedPerChainAndOwner() {
        let provider = YieldIncentivesClaimTrackerProvider()

        let tracker = provider.tracker(chainId: 143, userAddress: "0xABC")
        let sameOwner = provider.tracker(chainId: 143, userAddress: "0xabc")
        let otherChain = provider.tracker(chainId: 1, userAddress: "0xABC")
        let otherOwner = provider.tracker(chainId: 143, userAddress: "0xDEF")

        #expect(tracker === sameOwner)
        #expect(tracker !== otherChain)
        #expect(tracker !== otherOwner)
    }
}
