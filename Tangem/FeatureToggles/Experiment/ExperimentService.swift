//
//  ExperimentService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import Experiment

protocol ExperimentService {
    func configure()

    func variant(_ key: ExperimentFeatureFlagKey) -> Variant?
    func isOn(_ key: ExperimentFeatureFlagKey) -> Bool
}

final class CommonExperimentService {
    // MARK: - Services

    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Init

    init() {
        bind()
    }

    // MARK: - Private Properties

    private var _client: ExperimentClient?
    private var bag: Set<AnyCancellable> = []

    // MARK: - Public Implementation

    func configure() {
        guard !AppEnvironment.current.isDebug else {
            return
        }

        let config = ExperimentConfigBuilder()
            .automaticExposureTracking(true)
            .fetchOnStart(false)
            .build()

        _client = Experiment.initializeWithAmplitudeAnalytics(apiKey: keysManager.amplitudeApiKey, config: config)
    }

    // MARK: - Private Implementation

    private func bind() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { manager, event in
                switch event {
                case .selected(let userWalletId):
                    manager.setContext(for: userWalletId)
                default:
                    break
                }
            }
            .store(in: &bag)
    }

    private func setContext(for userWalletId: UserWalletId) {
        let ctx = ExperimentWalletContext.initial(for: userWalletId)
        Task { await refetch(for: ctx) }
    }

    private func refetch(for ctx: ExperimentWalletContext) async {
        let builder = ExperimentUserBuilder()
            .userId(ctx.userWalletId.stringValue)
            .region(ctx.region)
            .language(ctx.language)
            .version(ctx.appVersion)
            .os(ctx.osVersion)
            .deviceModel(ctx.deviceName)
            .userProperty(ExperimentWalletContext.ParameterKey.environment.rawValue, value: ctx.environment)

        ctx.attributes.forEach { builder.userProperty($0.key, value: $0.value) }

        let user = builder.build()

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                _client?.fetch(user: user) { client, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }

            AppLogger.info("Experiments fetched for wallet \(ctx.userWalletId)")
        } catch {
            AppLogger.error("Experiment fetch failed for wallet \(ctx.userWalletId)", error: error)
        }
    }
}

// MARK: - ExperimentService

extension CommonExperimentService: ExperimentService {
    func variant(_ key: ExperimentFeatureFlagKey) -> Variant? {
        _client?.variant(key.rawValue)
    }

    func isOn(_ key: ExperimentFeatureFlagKey) -> Bool {
        _client?.variant(key.rawValue).value == "on"
    }
}

// MARK: - Injection

private struct ExperimentServiceKey: InjectionKey {
    static var currentValue: ExperimentService = CommonExperimentService()
}

extension InjectedValues {
    var experimentService: ExperimentService {
        get { Self[ExperimentServiceKey.self] }
        set { Self[ExperimentServiceKey.self] = newValue }
    }
}
