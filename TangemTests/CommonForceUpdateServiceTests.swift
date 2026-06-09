//
//  CommonForceUpdateServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import Tangem

final class CommonForceUpdateServiceTests: XCTestCase {
    // MARK: - Force update

    func testForceUpdateAlwaysWins() {
        let dto = ApplicationVersionsDTO(forceUpdate: true, latestVersion: "5.40", minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"), .forceUpdate)

        let dtoNoVersion = ApplicationVersionsDTO(forceUpdate: true, latestVersion: nil, minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dtoNoVersion, currentVersion: nil), .forceUpdate)
    }

    // MARK: - Optional update

    func testOptionalUpdateWhenLatestIsHigher() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "5.41", minSupportedVersion: nil)
        XCTAssertEqual(
            CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"),
            .optionalUpdate(latestVersion: "5.41")
        )
    }

    func testOptionalUpdateUsesSemanticComparison() {
        // 5.37 must be greater than 5.9 with .numeric semantic comparison.
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "5.37", minSupportedVersion: nil)
        XCTAssertEqual(
            CommonForceUpdateService.mapState(from: dto, currentVersion: "5.9"),
            .optionalUpdate(latestVersion: "5.37")
        )
    }

    func testOptionalUpdateAcrossMajorVersions() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "6.0", minSupportedVersion: nil)
        XCTAssertEqual(
            CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"),
            .optionalUpdate(latestVersion: "6.0")
        )
    }

    // MARK: - Up to date

    func testUpToDateWhenVersionsEqual() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "5.40", minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"), .upToDate)
    }

    func testUpToDateWhenCurrentIsHigher() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "5.39", minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"), .upToDate)
    }

    // MARK: - Defensive

    func testUpToDateWhenLatestVersionMissing() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: nil, minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"), .upToDate)
    }

    func testUpToDateWhenLatestVersionEmpty() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "", minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: "5.40"), .upToDate)
    }

    func testUpToDateWhenCurrentVersionMissing() {
        let dto = ApplicationVersionsDTO(forceUpdate: false, latestVersion: "99.0", minSupportedVersion: nil)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: nil), .upToDate)
        XCTAssertEqual(CommonForceUpdateService.mapState(from: dto, currentVersion: ""), .upToDate)
    }
}
