//
//  GeoDefiner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation

protocol GeoIpRegionCodeStoring: AnyObject {
    var geoIpRegionCode: String? { get set }
    var geoIpRegionCodeUpdateDate: Date? { get set }
}

extension AppSettings: GeoIpRegionCodeStoring {}

class GeoDefiner: Initializable {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var geoIpRegionCode: String? {
        let now = dependencies.now()

        return state.withLock { $0.freshRegionCode(at: now) }
    }

    var phoneRegionCode: String? {
        dependencies.locale.region?.identifier.lowercased()
    }

    private let dependencies: Dependencies
    private let state: OSAllocatedUnfairLock<State>
    private var bag = Set<AnyCancellable>()

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
        state = OSAllocatedUnfairLock(
            initialState: State(
                regionCode: dependencies.storage.geoIpRegionCode,
                regionCodeUpdateDate: dependencies.storage.geoIpRegionCodeUpdateDate
            )
        )
    }

    func initialize() {
        bind()
        startUpdateIfNeeded()
    }

    func waitForUpdateIfNeeded() async {
        guard geoIpRegionCode == nil else {
            return
        }

        await startUpdateIfNeeded()?.value
    }

    @discardableResult
    func startUpdateIfNeeded() -> Task<Void, Never>? {
        let now = dependencies.monotonicNow()

        return state.withLock { state in
            if let task = state.updateTask {
                return task
            }

            if let lastAttempt = state.lastAttempt,
               lastAttempt.duration(to: now) < Constants.minimumUpdateInterval {
                return nil
            }

            let task = Task<Void, Never> { [weak self] in
                guard let self else {
                    return
                }

                await updateGeoIpRegionCode()
            }

            state.updateTask = task

            return task
        }
    }

    private func bind() {
        dependencies.notificationCenter
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .withWeakCaptureOf(self)
            .sink { definer, _ in
                definer.startUpdateIfNeeded()
            }
            .store(in: &bag)
    }

    private func updateGeoIpRegionCode() async {
        defer {
            let attempt = dependencies.monotonicNow()

            state.withLock { state in
                state.updateTask = nil
                state.lastAttempt = attempt
            }
        }

        guard let regionCode = try? await tangemApiService.loadGeo().async(), regionCode.isNotEmpty else {
            await dropStoredRegionCodeIfExpired()
            return
        }

        let normalizedRegionCode = regionCode.lowercased()
        let updateDate = dependencies.now()

        state.withLock { state in
            state.regionCode = normalizedRegionCode
            state.regionCodeUpdateDate = updateDate
        }

        await persistRegionCode(normalizedRegionCode, updateDate: updateDate)
    }

    private func dropStoredRegionCodeIfExpired() async {
        let now = dependencies.now()

        let dropped = state.withLock { state in
            guard state.regionCode != nil, state.freshRegionCode(at: now) == nil else {
                return false
            }

            state.regionCode = nil
            state.regionCodeUpdateDate = nil

            return true
        }

        guard dropped else {
            return
        }

        await persistRegionCode(nil, updateDate: nil)
    }

    @MainActor
    private func persistRegionCode(_ regionCode: String?, updateDate: Date?) {
        dependencies.storage.geoIpRegionCode = regionCode
        dependencies.storage.geoIpRegionCodeUpdateDate = updateDate
    }
}

// MARK: - Auxiliary types

extension GeoDefiner {
    struct Dependencies {
        var storage: any GeoIpRegionCodeStoring = AppSettings.shared
        var notificationCenter: NotificationCenter = .default
        var locale: Locale = .current
        var now: () -> Date = { Date() }
        var monotonicNow: () -> ContinuousClock.Instant = { .now }
    }
}

private extension GeoDefiner {
    struct State {
        var regionCode: String?
        var regionCodeUpdateDate: Date?
        var updateTask: Task<Void, Never>?
        var lastAttempt: ContinuousClock.Instant?

        func freshRegionCode(at now: Date) -> String? {
            guard let regionCodeUpdateDate,
                  (0 ..< Constants.timeToLive).contains(now.timeIntervalSince(regionCodeUpdateDate)) else {
                return nil
            }

            return regionCode
        }
    }

    enum Constants {
        static let minimumUpdateInterval: Duration = .seconds(10)
        static let timeToLive: TimeInterval = 24 * 60 * 60
    }
}
