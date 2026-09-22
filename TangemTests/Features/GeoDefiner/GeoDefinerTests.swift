//
//  GeoDefinerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemTestKit
import Testing
import UIKit
@testable import Tangem

@Suite("GeoDefiner", .tags(.geoDefiner))
final class GeoDefinerTests: LeakTrackingTestSuite {
    private let clock = GeoTestClock()
    private let notificationCenter = NotificationCenter()

    private func makeSUT(storage: InMemoryGeoIpRegionCodeStorage = .init()) -> GeoDefiner {
        let dependencies = GeoDefiner.Dependencies(
            storage: storage,
            notificationCenter: notificationCenter,
            locale: Locale(identifier: "de_DE"),
            now: clock.now,
            monotonicNow: clock.monotonicNow
        )

        return trackForMemoryLeaks(GeoDefiner(dependencies: dependencies))
    }

    private func makeStorage(regionCode: String, savedAgo age: TimeInterval) -> InMemoryGeoIpRegionCodeStorage {
        InMemoryGeoIpRegionCodeStorage(regionCode: regionCode, updateDate: clock.wall.addingTimeInterval(-age))
    }

    private func postWillEnterForeground() {
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    // MARK: - Persisted value

    @Test("A fresh persisted code is served immediately and no one waits for the refresh")
    func freshPersistedCodeIsServedWithoutWaiting() async {
        let apiSpy = GeoApiSpy(reply: .suspended)
        let storage = makeStorage(regionCode: "de", savedAgo: .hours(1))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(storage: storage)
            sut.initialize()

            await sut.waitForUpdateIfNeeded()
            #expect(sut.geoIpRegionCode == "de")

            let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
            #expect(requested)

            let refresh = sut.startUpdateIfNeeded()
            apiSpy.resumeSuspendedRequests(with: "us")
            await refresh?.value

            #expect(sut.geoIpRegionCode == "us")
        }
    }

    @Test("An expired persisted code is ignored and the caller waits for the network")
    func expiredPersistedCodeIsReplacedFromNetwork() async {
        let apiSpy = GeoApiSpy(reply: .regionCode("fr"))
        let storage = makeStorage(regionCode: "de", savedAgo: .hours(25))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(storage: storage)
            #expect(sut.geoIpRegionCode == nil)

            sut.initialize()
            await sut.waitForUpdateIfNeeded()

            #expect(sut.geoIpRegionCode == "fr")
            #expect(apiSpy.callCount == 1)
        }
    }

    @Test("A persisted date in the future is treated as expired")
    func futureUpdateDateIsTreatedAsExpired() {
        let storage = makeStorage(regionCode: "de", savedAgo: -.hours(1))

        let sut = makeSUT(storage: storage)

        #expect(sut.geoIpRegionCode == nil)
    }

    // MARK: - Network

    @Test("Concurrent waiters share a single request")
    func concurrentWaitersShareOneRequest() async {
        let apiSpy = GeoApiSpy(reply: .suspended)

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()

            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 5 {
                    group.addTask { await sut.waitForUpdateIfNeeded() }
                }

                let requested = await waitUntilConditionMet { apiSpy.callCount == 1 }
                #expect(requested)

                apiSpy.resumeSuspendedRequests(with: "fr")
            }

            #expect(apiSpy.callCount == 1)
            #expect(sut.geoIpRegionCode == "fr")
        }
    }

    @Test("A successful response is lowercased and persisted with its date")
    func successfulResponseIsPersisted() async {
        let apiSpy = GeoApiSpy(reply: .regionCode("FR"))
        let storage = InMemoryGeoIpRegionCodeStorage()

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(storage: storage)

            await sut.startUpdateIfNeeded()?.value

            #expect(sut.geoIpRegionCode == "fr")
            #expect(storage.geoIpRegionCode == "fr")
            #expect(storage.geoIpRegionCodeUpdateDate == clock.wall)
        }
    }

    @Test("An empty response is treated as a failure")
    func emptyResponseIsTreatedAsFailure() async {
        let apiSpy = GeoApiSpy(reply: .regionCode(""))
        let storage = makeStorage(regionCode: "de", savedAgo: .hours(25))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(storage: storage)

            await sut.startUpdateIfNeeded()?.value

            #expect(sut.geoIpRegionCode == nil)
            #expect(storage.geoIpRegionCode == nil)
        }
    }

    @Test("A failed refresh keeps a fresh persisted code")
    func failedRefreshKeepsFreshCode() async {
        let apiSpy = GeoApiSpy(reply: .failure)
        let storage = makeStorage(regionCode: "de", savedAgo: .hours(1))
        let savedDate = storage.geoIpRegionCodeUpdateDate

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(storage: storage)

            await sut.startUpdateIfNeeded()?.value

            #expect(sut.geoIpRegionCode == "de")
            #expect(storage.geoIpRegionCode == "de")
            #expect(storage.geoIpRegionCodeUpdateDate == savedDate)
        }
    }

    @Test("A failed refresh drops an expired persisted code")
    func failedRefreshDropsExpiredCode() async {
        let apiSpy = GeoApiSpy(reply: .failure)
        let storage = makeStorage(regionCode: "de", savedAgo: .hours(25))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT(storage: storage)

            await sut.startUpdateIfNeeded()?.value

            #expect(sut.geoIpRegionCode == nil)
            #expect(storage.geoIpRegionCode == nil)
            #expect(storage.geoIpRegionCodeUpdateDate == nil)
        }
    }

    // MARK: - Throttling

    @Test("Foreground refreshes are throttled by the monotonic clock")
    func foregroundRefreshIsThrottled() async {
        let apiSpy = GeoApiSpy(reply: .regionCode("fr"))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            sut.initialize()
            await sut.waitForUpdateIfNeeded()
            #expect(apiSpy.callCount == 1)

            postWillEnterForeground()
            #expect(sut.startUpdateIfNeeded() == nil)
            #expect(apiSpy.callCount == 1)

            apiSpy.reply = .suspended
            clock.advanceMonotonic(by: .seconds(11))
            postWillEnterForeground()

            let requested = await waitUntilConditionMet { apiSpy.callCount == 2 }
            #expect(requested)

            let refresh = sut.startUpdateIfNeeded()
            apiSpy.resumeSuspendedRequests(with: "us")
            await refresh?.value

            #expect(sut.geoIpRegionCode == "us")
        }
    }

    @Test("Moving the wall clock backwards does not block the throttle")
    func throttleIgnoresWallClockChanges() async {
        let apiSpy = GeoApiSpy(reply: .regionCode("fr"))

        await withInjectedTangemApiService(apiSpy.fake) {
            let sut = makeSUT()
            await sut.startUpdateIfNeeded()?.value
            #expect(apiSpy.callCount == 1)

            clock.wall = clock.wall.addingTimeInterval(-.hours(24))
            clock.advanceMonotonic(by: .seconds(11))

            await sut.startUpdateIfNeeded()?.value
            #expect(apiSpy.callCount == 2)
        }
    }
}

private extension TimeInterval {
    static func hours(_ hours: Double) -> TimeInterval {
        hours * 60 * 60
    }
}
