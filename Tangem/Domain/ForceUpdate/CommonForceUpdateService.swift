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
    private var checkTask: Task<Void, Never>?

    init(cache: ForceUpdateCache = UserDefaultsForceUpdateCache()) {
        self.cache = cache
        loadStateFromCache()
    }

    deinit {
        checkTask?.cancel()
    }

    static func mapState(
        from dto: ApplicationVersionsDTO,
        currentVersion: String?,
        currentOSVersion: String?
    ) -> ForceUpdateState {
        guard let currentVersion, !currentVersion.isEmpty else {
            return .upToDate
        }

        if let criticalVersion = dto.criticalVersion,
           !criticalVersion.isEmpty,
           isVersion(currentVersion, lessThanOrEqualTo: criticalVersion) {
            if let criticalOSVersion = dto.criticalOSVersion,
               !criticalOSVersion.isEmpty,
               let currentOSVersion,
               isVersion(currentOSVersion, lessThan: criticalOSVersion) {
                return .forceUpdate(reason: .brick)
            }
            return .forceUpdate(reason: .requiresAppUpdate)
        }

        if let minSupportedVersion = dto.minSupportedVersion,
           !minSupportedVersion.isEmpty,
           isVersion(currentVersion, lessThanOrEqualTo: minSupportedVersion) {
            if let minSupportedOSVersion = dto.minSupportedOSVersion,
               !minSupportedOSVersion.isEmpty,
               let currentOSVersion,
               isVersion(currentOSVersion, lessThan: minSupportedOSVersion) {
                return .forceUpdate(reason: .requiresOSUpdate)
            }
            return .forceUpdate(reason: .requiresAppUpdate)
        }

        if let latestVersion = dto.latestVersion,
           !latestVersion.isEmpty,
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
        guard FeatureProvider.isAvailable(.forceUpdate) else {
            stateSubject.send(.upToDate)
            return
        }
        guard let dto = cache.dto else {
            stateSubject.send(.upToDate)
            return
        }
        stateSubject.send(Self.mapState(from: dto, currentVersion: currentAppVersion, currentOSVersion: currentOSVersion))
    }

    private func runFetch(applyToState: Bool) {
        guard FeatureProvider.isAvailable(.forceUpdate) else { return }

        checkTask?.cancel()
        checkTask = runTask(in: self) { service in
            do {
                let dto = try await service.apiService.loadApplicationVersions()
                service.cache.dto = dto

                guard applyToState else { return }

                service.stateSubject.send(
                    Self.mapState(
                        from: dto,
                        currentVersion: service.currentAppVersion,
                        currentOSVersion: service.currentOSVersion
                    )
                )
            } catch {
                AppLogger.error("Failed to load application versions", error: error)
            }
        }
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

    func refreshCache() {
        runFetch(applyToState: false)
    }

    func refreshAndApply() {
        runFetch(applyToState: true)
    }
}
