//
//  CommonForceUpdateServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("CommonForceUpdateService.mapState")
struct CommonForceUpdateServiceTests {
    // MARK: - Critical version

    @Test("BRICK when app ≤ critical and OS is too old")
    func brickWhenAppAtOrBelowCriticalAndOSTooOld() {
        let dto = makeDTO(criticalVersion: "5.40", criticalOSVersion: "17.0")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "16.5") == .forceUpdate(reason: .brick))
        #expect(map(dto, currentVersion: "5.30", currentOSVersion: "16.5") == .forceUpdate(reason: .brick))
    }

    @Test("Force app update when app ≤ critical and OS is OK")
    func forceAppUpdateWhenAppAtOrBelowCriticalAndOSOK() {
        let dto = makeDTO(criticalVersion: "5.40", criticalOSVersion: "17.0")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .forceUpdate(reason: .requiresAppUpdate))
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "18.1") == .forceUpdate(reason: .requiresAppUpdate))
    }

    @Test("Force app update when app ≤ critical and criticalOSVersion is nil")
    func forceAppUpdateWhenAppAtOrBelowCriticalAndOSCriticalIsNil() {
        let dto = makeDTO(criticalVersion: "5.40", criticalOSVersion: nil)
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "1.0") == .forceUpdate(reason: .requiresAppUpdate))
    }

    // MARK: - Min supported version

    @Test("Requires OS update when app ≤ minSupported and OS is too old")
    func requiresOSUpdateWhenAppAtOrBelowMinSupportedAndOSTooOld() {
        let dto = makeDTO(minSupportedVersion: "5.40", minSupportedOSVersion: "17.0")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "16.5") == .forceUpdate(reason: .requiresOSUpdate))
    }

    @Test("Force app update when app ≤ minSupported and OS is OK")
    func forceAppUpdateWhenAppAtOrBelowMinSupportedAndOSOK() {
        let dto = makeDTO(minSupportedVersion: "5.40", minSupportedOSVersion: "17.0")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .forceUpdate(reason: .requiresAppUpdate))
    }

    @Test("Force app update when minSupportedOSVersion is nil")
    func forceAppUpdateWhenMinSupportedAndOSVersionIsNil() {
        let dto = makeDTO(minSupportedVersion: "5.40", minSupportedOSVersion: nil)
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "1.0") == .forceUpdate(reason: .requiresAppUpdate))
    }

    // MARK: - Critical takes precedence

    @Test("Critical branch wins over minSupported branch")
    func criticalTakesPrecedence() {
        let dto = makeDTO(
            criticalVersion: "5.40",
            criticalOSVersion: "17.0",
            minSupportedVersion: "5.40",
            minSupportedOSVersion: "17.0"
        )
        // Both critical and minSupported match the app version, but critical wins → brick (since OS too old).
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "16.5") == .forceUpdate(reason: .brick))
    }

    // MARK: - Optional update (latest)

    @Test("Optional update when app is below latest")
    func optionalUpdateWhenAppBelowLatest() {
        let dto = makeDTO(latestVersion: "5.41")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .optionalUpdate(latestVersion: "5.41"))
    }

    @Test("Optional update respects semantic (numeric) comparison")
    func optionalUpdateUsesSemanticComparison() {
        // 5.37 must be greater than 5.9 with .numeric semantic comparison.
        let dto = makeDTO(latestVersion: "5.37")
        #expect(map(dto, currentVersion: "5.9", currentOSVersion: "17.0") == .optionalUpdate(latestVersion: "5.37"))
    }

    // MARK: - Up to date

    @Test("Up to date when all thresholds are nil")
    func upToDateWhenAllNil() {
        #expect(map(makeDTO(), currentVersion: "5.40", currentOSVersion: "17.0") == .upToDate)
    }

    @Test("Up to date when app equals latest")
    func upToDateWhenAppEqualsLatest() {
        let dto = makeDTO(latestVersion: "5.40")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .upToDate)
    }

    @Test("Up to date when app is above all thresholds")
    func upToDateWhenAppAboveAllThresholds() {
        let dto = makeDTO(
            criticalVersion: "5.30",
            criticalOSVersion: "17.0",
            minSupportedVersion: "5.35",
            minSupportedOSVersion: "17.0",
            latestVersion: "5.40"
        )
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .upToDate)
    }

    // MARK: - Defensive

    @Test("Up to date when current version is missing or empty")
    func upToDateWhenCurrentVersionMissingOrEmpty() {
        let dto = makeDTO(criticalVersion: "5.40", latestVersion: "99.0")
        #expect(map(dto, currentVersion: nil, currentOSVersion: "17.0") == .upToDate)
        #expect(map(dto, currentVersion: "", currentOSVersion: "17.0") == .upToDate)
    }

    @Test("Up to date when latestVersion is empty and other thresholds are nil")
    func upToDateWhenLatestVersionEmptyAndOthersNil() {
        let dto = makeDTO(latestVersion: "")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .upToDate)
    }

    @Test("Empty criticalVersion is ignored")
    func emptyCriticalVersionIsIgnored() {
        let dto = makeDTO(criticalVersion: "", criticalOSVersion: "99.0")
        #expect(map(dto, currentVersion: "5.40", currentOSVersion: "17.0") == .upToDate)
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
