//
//  CommonForceUpdateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemFoundation

final class CommonForceUpdateService {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let cache: ForceUpdateCache
    private let stateSubject = CurrentValueSubject<ForceUpdateState, Never>(.unknown)
    private var checkCancellable: AnyCancellable?
    private var osUpdateWarningDismissed = false

    init(cache: ForceUpdateCache) {
        self.cache = cache
        loadStateFromCache()
    }

    static func mapState(
        from dto: ApplicationVersionsDTO,
        currentVersion: String?,
        currentOSVersion: String?
    ) -> ForceUpdateState {
        guard let currentVersion = currentVersion?.nilIfEmpty else {
            return .upToDate
        }

        if let criticalVersion = dto.criticalVersion?.nilIfEmpty,
           isVersion(currentVersion, lessThanOrEqualTo: criticalVersion) {
            if let criticalOSVersion = dto.criticalOSVersion?.nilIfEmpty,
               let currentOSVersion = currentOSVersion?.nilIfEmpty,
               isVersion(currentOSVersion, lessThan: criticalOSVersion) {
                return .forceUpdate(reason: .brick)
            }
            return .forceUpdate(reason: .requiresAppUpdate)
        }

        if let minSupportedVersion = dto.minSupportedVersion?.nilIfEmpty,
           isVersion(currentVersion, lessThanOrEqualTo: minSupportedVersion) {
            if let minSupportedOSVersion = dto.minSupportedOSVersion?.nilIfEmpty,
               let currentOSVersion = currentOSVersion?.nilIfEmpty,
               isVersion(currentOSVersion, lessThan: minSupportedOSVersion) {
                return .forceUpdate(reason: .requiresOSUpdate)
            }
            return .forceUpdate(reason: .requiresAppUpdate)
        }

        if let latestVersion = dto.latestVersion?.nilIfEmpty,
           isVersion(currentVersion, lessThan: latestVersion) {
            return .optionalUpdate(latestVersion: latestVersion)
        }

        return .upToDate
    }

    private static func isVersion(_ lhs: String, lessThan rhs: String) -> Bool {
        lhs.compare(rhs, options: .numeric) == .orderedAscending
    }

    private static func isVersion(_ lhs: String, lessThanOrEqualTo rhs: String) -> Bool {
        let result = lhs.compare(rhs, options: .numeric)
        return result == .orderedAscending || result == .orderedSame
    }

    // MARK: - Private

    private func loadStateFromCache() {
        guard FeatureProvider.isAvailable(.forceUpdate), let dto = cache.dto else {
            return
        }
        stateSubject.send(Self.mapState(from: dto, currentVersion: currentAppVersion, currentOSVersion: currentOSVersion))
    }

    private func runFetch(applyToState: Bool) {
        guard FeatureProvider.isAvailable(.forceUpdate) else { return }

        checkCancellable = runTask(in: self) { service in
            do {
                let dto = try await service.apiService.loadApplicationVersions()
                try Task.checkCancellation()

                service.cache.dto = dto

                guard applyToState else { return }
                await MainActor.run {
                    service.stateSubject.send(
                        Self.mapState(
                            from: dto,
                            currentVersion: service.currentAppVersion,
                            currentOSVersion: service.currentOSVersion
                        )
                    )
                }
            } catch is CancellationError {
                // A superseded request — not a failure, ignore.
            } catch {
                AppLogger.error("Failed to load application versions", error: error)
            }
        }
        .eraseToAnyCancellable()
    }

    private var currentAppVersion: String? {
        InfoDictionaryUtils.version.value()
    }

    private var currentOSVersion: String {
        UIDevice.current.systemVersion
    }
}

// MARK: - ForceUpdateService

extension CommonForceUpdateService: ForceUpdateService {
    var state: ForceUpdateState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<ForceUpdateState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var startupBlockingReason: ForceUpdateReason? {
        guard let reason = state.forceUpdateReason else {
            return nil
        }

        // OS-update is a soft warning: once the user dismisses it, stop blocking for the session.
        if reason == .requiresOSUpdate, osUpdateWarningDismissed {
            return nil
        }

        return reason
    }

    func refreshCache() {
        runFetch(applyToState: false)
    }

    func refreshAndApply() {
        runFetch(applyToState: true)
    }

    func dismissOSUpdateWarning() {
        osUpdateWarningDismissed = true
    }
}
