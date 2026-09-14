//
//  CommonGeoEligibilityServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CommonGeoEligibilityService", .tags(.geoDefiner))
final class CommonGeoEligibilityServiceTests: LeakTrackingTestSuite {
    private let clock = GeoTestClock()

    private func makeSUT(geoIpRegionCode: String?, localeIdentifier: String) -> CommonGeoEligibilityService {
        let storage = InMemoryGeoIpRegionCodeStorage(
            regionCode: geoIpRegionCode,
            updateDate: geoIpRegionCode == nil ? nil : clock.wall
        )

        let dependencies = GeoDefiner.Dependencies(
            storage: storage,
            notificationCenter: NotificationCenter(),
            locale: Locale(identifier: localeIdentifier),
            now: clock.now,
            monotonicNow: clock.monotonicNow
        )

        return trackForMemoryLeaks(CommonGeoEligibilityService(geoDefiner: GeoDefiner(dependencies: dependencies)))
    }

    @Test("The GeoIP region wins over the device locale")
    func geoIpRegionWinsOverLocale() {
        let sut = makeSUT(geoIpRegionCode: "gb", localeIdentifier: "de_DE")

        #expect(sut.isUK)
        #expect(!sut.isApplePayAllowed)
    }

    @Test("The device locale is used when the GeoIP region is unknown")
    func localeIsUsedWithoutGeoIpRegion() {
        let sut = makeSUT(geoIpRegionCode: nil, localeIdentifier: "en_GB")

        #expect(sut.isUK)
        #expect(!sut.isApplePayAllowed)
    }

    @Test("An unknown region does not restrict Apple Pay")
    func unknownRegionAllowsApplePay() {
        let sut = makeSUT(geoIpRegionCode: nil, localeIdentifier: "en")

        #expect(!sut.isUK)
        #expect(sut.isApplePayAllowed)
    }

    @Test("Apple Pay availability follows the restricted regions list", arguments: [
        ("us", false),
        ("ch", true),
        ("de", true),
    ])
    func applePayFollowsRestrictedRegions(regionCode: String, isAllowed: Bool) {
        let sut = makeSUT(geoIpRegionCode: regionCode, localeIdentifier: "en_GB")

        #expect(sut.isApplePayAllowed == isAllowed)
    }

    @Test("Fetching the region falls back to the device locale when the network fails")
    func fetchFallsBackToLocaleOnFailure() async {
        let apiSpy = GeoApiSpy(reply: .failure)

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(geoIpRegionCode: nil, localeIdentifier: "en_GB")

            let regionCode = await sut.fetchGeoIpRegionCode()

            #expect(regionCode == "gb")
            #expect(apiSpy.callCount == 1)
        }
    }

    @Test("Fetching the region returns the GeoIP country once resolved")
    func fetchReturnsGeoIpRegion() async {
        let apiSpy = GeoApiSpy(reply: .regionCode("FR"))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(geoIpRegionCode: nil, localeIdentifier: "en_GB")

            let regionCode = await sut.fetchGeoIpRegionCode()

            #expect(regionCode == "fr")
        }
    }
}
