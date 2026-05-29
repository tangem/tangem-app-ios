//
//  CommonAppUpdateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import UIKit
import TangemFoundation

final class CommonAppUpdateService {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let stateSubject = CurrentValueSubject<AppUpdateState, Never>(.unknown)
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

    private func mapState(from dto: ApplicationVersionsDTO) -> AppUpdateState {
        if dto.forceUpdate {
            return .forceUpdate
        }

        guard let latestVersion = dto.latestVersion,
              let currentVersion: String = InfoDictionaryUtils.version.value(),
              !latestVersion.isEmpty,
              !currentVersion.isEmpty else {
            return .upToDate
        }

        let isOutdated = currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
        return isOutdated ? .optionalUpdate(latestVersion: latestVersion) : .upToDate
    }
}

// MARK: - AppUpdateService

extension CommonAppUpdateService: AppUpdateService {
    var state: AppUpdateState {
        stateSubject.value
    }

    var statePublisher: AnyPublisher<AppUpdateState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func checkForUpdates() {
        checkTask?.cancel()
        checkTask = runTask(in: self) { service in
            do {
                let dto = try await service.apiService.loadApplicationVersions()
                service.stateSubject.send(service.mapState(from: dto))
            } catch {
                AppLogger.error("Failed to load application versions", error: error)
            }
        }
    }
}
