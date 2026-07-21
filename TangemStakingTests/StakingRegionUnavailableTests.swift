//
//  StakingRegionUnavailableTests.swift
//  TangemStakingTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemStaking

final class StakingRegionUnavailableTests: XCTestCase {
    // MARK: - Error.isStakingRegionUnavailable

    func testRawRegionErrorIsDetected() {
        let error: Error = P2PStakingError.regionUnavailable
        XCTAssertTrue(error.isStakingRegionUnavailable)
    }

    func testWrappedRegionErrorIsDetected() {
        // The yield path wraps the p2p error when no target amount limits are cached.
        let error: Error = StakingAvailabilityError.dataUnavailable(underlying: P2PStakingError.regionUnavailable)
        XCTAssertTrue(error.isStakingRegionUnavailable)
    }

    func testOtherP2PErrorIsNotRegion() {
        let error: Error = P2PStakingError.invalidVault
        XCTAssertFalse(error.isStakingRegionUnavailable)
    }

    func testWrappedNonRegionErrorIsNotRegion() {
        let error: Error = StakingAvailabilityError.dataUnavailable(underlying: P2PStakingError.invalidVault)
        XCTAssertFalse(error.isStakingRegionUnavailable)
    }

    func testUnrelatedErrorIsNotRegion() {
        let error: Error = NSError(domain: "test", code: 1)
        XCTAssertFalse(error.isStakingRegionUnavailable)
    }

    // MARK: - StakingManagerState.unavailableInRegion

    private func makeCachedState() -> CachedStakingManagerState {
        CachedStakingManagerState(rewardType: .apy, apy: 5.5, stakeState: .staked(balance: 2), date: Date())
    }

    func testRegionStateSurfacesCachedValues() {
        let cached = makeCachedState()
        let state = StakingManagerState.unavailableInRegion(cached: cached)

        XCTAssertEqual(state.apy, 5.5)
        XCTAssertEqual(state.rewardType, .apy)
        XCTAssertTrue(state.isActive)
        XCTAssertNil(state.yieldInfo)
        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isSuccessfullyLoaded)
        XCTAssertEqual(state.description, "unavailableInRegion")
    }

    func testRegionStateWithoutCacheHasNoValues() {
        let state = StakingManagerState.unavailableInRegion(cached: nil)

        XCTAssertNil(state.apy)
        XCTAssertNil(state.rewardType)
        XCTAssertFalse(state.isActive)
        XCTAssertNil(state.yieldInfo)
    }
}
