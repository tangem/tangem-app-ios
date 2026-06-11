//
//  CommonForceUpdateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import UIKit
import TangemFoundation

final class CommonForceUpdateService {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let stateSubject = CurrentValueSubject<ForceUpdateState, Never>(.unknown)
    private var checkTask: Task<Void, Never>?
    private var didEnterBackground = false
    private var bag = Set<AnyCancellable>()

    init() {
        bindAppLifecycle()
    }

    deinit {
        checkTask?.cancel()
    }

    private func bindAppLifecycle() {
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .withWeakCaptureOf(self)
            .sink { service, _ in service.didEnterBackground = true }
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .withWeakCaptureOf(self)
            .sink { service, _ in
                guard service.didEnterBackground else { return }
                service.checkForUpdates()
            }
            .store(in: &bag)
    }

    static func mapState(from dto: ApplicationVersionsDTO, currentVersion: String?) -> ForceUpdateState {
        if dto.forceUpdate {
            return .forceUpdate
        }

        guard let latestVersion = dto.latestVersion,
              !latestVersion.isEmpty,
              let currentVersion,
              !currentVersion.isEmpty else {
            return .upToDate
        }

        let isOutdated = currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
        return isOutdated ? .optionalUpdate(latestVersion: latestVersion) : .upToDate
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

    func checkForUpdates() {
        guard FeatureProvider.isAvailable(.forceUpdate) else { return }

        checkTask?.cancel()
        checkTask = runTask(in: self) { service in
            do {
                let dto = try await service.apiService.loadApplicationVersions()
                let currentVersion: String? = InfoDictionaryUtils.version.value()
                service.stateSubject.send(Self.mapState(from: dto, currentVersion: currentVersion))
            } catch {
                AppLogger.error("Failed to load application versions", error: error)
            }
        }
    }
}
