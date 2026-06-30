//
//  CommonForceUpdateServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

final class CommonForceUpdateServiceTests: XCTestCase {
    // MARK: - Critical version

    func testBrickWhenAppAtOrBelowCriticalAndOSTooOld() {
        let dto = makeDTO(criticalVersion: "5.40", criticalOSVersion: "17.0")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "16.5"), .forceUpdate(reason: .brick))
        XCTAssertEqual(map(dto, currentVersion: "5.30", currentOSVersion: "16.5"), .forceUpdate(reason: .brick))
    }

    func testForceAppUpdateWhenAppAtOrBelowCriticalAndOSOK() {
        let dto = makeDTO(criticalVersion: "5.40", criticalOSVersion: "17.0")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .forceUpdate(reason: .requiresAppUpdate))
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "18.1"), .forceUpdate(reason: .requiresAppUpdate))
    }

    func testForceAppUpdateWhenAppAtOrBelowCriticalAndOSCriticalIsNil() {
        let dto = makeDTO(criticalVersion: "5.40", criticalOSVersion: nil)
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "1.0"), .forceUpdate(reason: .requiresAppUpdate))
    }

    // MARK: - Min supported version

    func testRequiresOSUpdateWhenAppAtOrBelowMinSupportedAndOSTooOld() {
        let dto = makeDTO(minSupportedVersion: "5.40", minSupportedOSVersion: "17.0")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "16.5"), .forceUpdate(reason: .requiresOSUpdate))
    }

    func testForceAppUpdateWhenAppAtOrBelowMinSupportedAndOSOK() {
        let dto = makeDTO(minSupportedVersion: "5.40", minSupportedOSVersion: "17.0")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .forceUpdate(reason: .requiresAppUpdate))
    }

    func testForceAppUpdateWhenMinSupportedAndOSVersionIsNil() {
        let dto = makeDTO(minSupportedVersion: "5.40", minSupportedOSVersion: nil)
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "1.0"), .forceUpdate(reason: .requiresAppUpdate))
    }

    // MARK: - Critical takes precedence

    func testCriticalTakesPrecedence() {
        let dto = makeDTO(
            criticalVersion: "5.40",
            criticalOSVersion: "17.0",
            minSupportedVersion: "5.40",
            minSupportedOSVersion: "17.0"
        )
        // Both critical and minSupported match the app version, but critical wins → brick (since OS too old).
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "16.5"), .forceUpdate(reason: .brick))
    }

    // MARK: - Optional update (latest)

    func testOptionalUpdateWhenAppBelowLatest() {
        let dto = makeDTO(latestVersion: "5.41")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .optionalUpdate(latestVersion: "5.41"))
    }

    func testOptionalUpdateUsesSemanticComparison() {
        // 5.37 must be greater than 5.9 with .numeric semantic comparison.
        let dto = makeDTO(latestVersion: "5.37")
        XCTAssertEqual(map(dto, currentVersion: "5.9", currentOSVersion: "17.0"), .optionalUpdate(latestVersion: "5.37"))
    }

    // MARK: - Up to date

    func testUpToDateWhenAllNil() {
        XCTAssertEqual(map(makeDTO(), currentVersion: "5.40", currentOSVersion: "17.0"), .upToDate)
    }

    func testUpToDateWhenAppEqualsLatest() {
        let dto = makeDTO(latestVersion: "5.40")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .upToDate)
    }

    func testUpToDateWhenAppAboveAllThresholds() {
        let dto = makeDTO(
            criticalVersion: "5.30",
            criticalOSVersion: "17.0",
            minSupportedVersion: "5.35",
            minSupportedOSVersion: "17.0",
            latestVersion: "5.40"
        )
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .upToDate)
    }

    // MARK: - Defensive

    func testUpToDateWhenCurrentVersionMissingOrEmpty() {
        let dto = makeDTO(criticalVersion: "5.40", latestVersion: "99.0")
        XCTAssertEqual(map(dto, currentVersion: nil, currentOSVersion: "17.0"), .upToDate)
        XCTAssertEqual(map(dto, currentVersion: "", currentOSVersion: "17.0"), .upToDate)
    }

    func testUpToDateWhenLatestVersionEmptyAndOthersNil() {
        let dto = makeDTO(latestVersion: "")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .upToDate)
    }

    func testEmptyCriticalVersionIsIgnored() {
        let dto = makeDTO(criticalVersion: "", criticalOSVersion: "99.0")
        XCTAssertEqual(map(dto, currentVersion: "5.40", currentOSVersion: "17.0"), .upToDate)
    }
}

// MARK: - Helpers

private extension CommonForceUpdateServiceTests {
    func map(_ dto: ApplicationVersionsDTO, currentVersion: String?, currentOSVersion: String?) -> ForceUpdateState {
        CommonForceUpdateService.mapState(from: dto, currentVersion: currentVersion, currentOSVersion: currentOSVersion)
    }

    func makeDTO(
        criticalVersion: String? = nil,
        criticalOSVersion: String? = nil,
        minSupportedVersion: String? = nil,
        minSupportedOSVersion: String? = nil,
        latestVersion: String? = nil
    ) -> ApplicationVersionsDTO {
        ApplicationVersionsDTO(
            criticalVersion: criticalVersion,
            criticalOSVersion: criticalOSVersion,
            minSupportedVersion: minSupportedVersion,
            minSupportedOSVersion: minSupportedOSVersion,
            latestVersion: latestVersion
        )
    }
}
