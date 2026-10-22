//
//  ExperimentService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import TangemSdk
import TangemFoundation
import Experiment

protocol ExperimentService {
    var variantsPublisher: AnyPublisher<Void, Never> { get }
    var hasFreshVariants: Bool { get }

    func configure()

    func variant(_ key: ExperimentFeatureFlagKey) -> Variant?
    func isOn(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool
    func isOnWithoutExposure(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool
    func waitForVariants(ofWalletMatching isMatching: @escaping (UserWalletId) -> Bool) async -> Bool

    @MainActor
    func hasFetchedVariants(for userWalletId: UserWalletId) -> Bool
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
    private var refetchTask: Task<Void, Never>?
    private let variantsSubject = PassthroughSubject<Void, Never>()
    private let freshVariants = OSAllocatedUnfairLock(initialState: false)
    private let fetchedUserWalletIdsSubject = CurrentValueSubject<Set<UserWalletId>, Never>([])
    @MainActor private var fetchedUserWalletId: UserWalletId?

    // MARK: - Public Implementation

    func configure() {
        let config = ExperimentConfigBuilder()
            .automaticExposureTracking(true)
            .fetchOnStart(false)
            .fetchRetryOnFailure(false)
            .exposureTrackingProvider(AmplitudeExposureTrackingProvider())
            .build()

        _client = Experiment.initialize(apiKey: keysManager.amplitudeApiKey, config: config)

        setContext(for: nil)
    }

    // MARK: - Private Implementation

    private func bind() {
        userWalletRepository
            .eventProvider
            .compactMap { event -> UserWalletId? in
                guard case .selected(let userWalletId) = event else {
                    return nil
                }

                return userWalletId
            }
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { manager, userWalletId in
                manager.setContext(for: userWalletId)
            }
            .store(in: &bag)
    }

    private func configuredClient(for key: ExperimentFeatureFlagKey) -> ExperimentClient? {
        guard let client = _client else {
            AppLogger.warning("Experiment \(key.rawValue) read before configure(), answering as not enrolled")
            assertionFailure("Experiment \(key.rawValue) read before configure()")
            return nil
        }

        return client
    }

    private func setContext(for userWalletId: UserWalletId?) {
        let ctx = ExperimentWalletContext.initial(for: userWalletId)

        let previousRefetchTask = refetchTask

        previousRefetchTask?.cancel()
        refetchTask = runTask(in: self) { service in
            await previousRefetchTask?.value
            await service.refetch(for: ctx)
        }
    }

    private func refetch(for ctx: ExperimentWalletContext) async {
        await MainActor.run { fetchedUserWalletId = nil }
        freshVariants.withLock { $0 = false }
        variantsSubject.send()

        let builder = ExperimentUserBuilder()
            .userId(ctx.userWalletId?.hashedStringValue)
            .region(ctx.region)
            .language(ctx.language)
            .version(ctx.appVersion)
            .os(ctx.osVersion)
            .deviceModel(ctx.deviceName)
            .userProperty(ExperimentWalletContext.ParameterKey.environment.rawValue, value: ctx.environment)

        ctx.attributes.forEach { builder.userProperty($0.key, value: $0.value) }

        let user = builder.build()

        guard let client = _client else {
            AppLogger.info("Experiment client is nil, skipping fetch for wallet")
            return
        }

        for (attempt, delay) in Constants.fetchRetryDelays.enumerated() {
            do {
                try await Task.sleep(for: delay)
                try await fetch(user: user, with: client)

                await MainActor.run { fetchedUserWalletId = ctx.userWalletId }
                freshVariants.withLock { $0 = true }
                variantsSubject.send()

                if let userWalletId = ctx.userWalletId {
                    fetchedUserWalletIdsSubject.send(fetchedUserWalletIdsSubject.value.union([userWalletId]))
                }

                AppLogger.info("Experiments fetched")
                return
            } catch is CancellationError {
                AppLogger.info("Experiment fetch cancelled")
                return
            } catch {
                AppLogger.error("Experiment fetch attempt \(attempt + 1) failed", error: error)
            }
        }

        variantsSubject.send()
    }

    private func fetch(user: ExperimentUser, with client: ExperimentClient) async throws {
        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            client.fetch(user: user) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        try Task.checkCancellation()
    }
}

// MARK: - ExperimentService

extension CommonExperimentService: ExperimentService {
    var variantsPublisher: AnyPublisher<Void, Never> {
        variantsSubject.eraseToAnyPublisher()
    }

    var hasFreshVariants: Bool {
        freshVariants.withLock { $0 }
    }

    func variant(_ key: ExperimentFeatureFlagKey) -> Variant? {
        guard let client = configuredClient(for: key) else { return nil }

        return client.variant(key.rawValue)
    }

    func isOnWithoutExposure(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        guard let client = configuredClient(for: key) else { return false }

        return client.all()[key.rawValue]?.value == variant.rawValue
    }

    func isOn(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        guard let client = configuredClient(for: key) else { return false }

        return client.variant(key.rawValue).value == variant.rawValue
    }

    func waitForVariants(ofWalletMatching isMatching: @escaping (UserWalletId) -> Bool) async -> Bool {
        let fetched = try? await fetchedUserWalletIdsSubject
            .first { $0.contains(where: isMatching) }
            .async()

        return fetched != nil
    }

    @MainActor
    func hasFetchedVariants(for userWalletId: UserWalletId) -> Bool {
        fetchedUserWalletId == userWalletId
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

// MARK: - Constants

private extension CommonExperimentService {
    enum Constants {
        static let fetchRetryDelays: [Duration] = [.zero, .seconds(2), .seconds(5), .seconds(15)]
    }
}
