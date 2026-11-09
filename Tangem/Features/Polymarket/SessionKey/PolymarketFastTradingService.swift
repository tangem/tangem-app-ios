//
//  PolymarketFastTradingService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemNetworkUtils
import TangemPolymarket

@MainActor
protocol PolymarketFastTradingServicing: AnyObject {
    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> { get }

    var state: PolymarketFastTradingState { get }

    func bannerPublisher(includingForeignSigners: Bool) -> AnyPublisher<PolymarketFastTradingBanner?, Never>

    var failurePublisher: AnyPublisher<PolymarketFastTradingFailure, Never> { get }

    func refresh() async

    func enable() async throws

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws

    func renew() async throws

    func replace(previous: PolymarketSessionKey, revokesPrevious: Bool) async throws

    func revoke(sessionKeyAddress: String) async throws

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws

    func dismissBanner(_ banner: PolymarketFastTradingBanner)
}

@MainActor
final class CommonPolymarketFastTradingService {
    private let userWalletId: UserWalletId
    private let manager: PolymarketSessionKeyManaging
    private let keyStore: PolymarketSessionKeyStore
    private let deviceIdProvider: PolymarketDeviceIdProviding
    private let clobService: PolymarketCLOBService
    private let credentialsRepository: PolymarketCredentialsRepository
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let bannerDismissals: PolymarketFastTradingBannerDismissals
    private let pollDelayProvider: PollDelayProvider
    private let now: () -> Date

    private let stateSubject = CurrentValueSubject<PolymarketFastTradingState, Never>(.loading)
    private let dismissalsSubject = CurrentValueSubject<Int, Never>(0)
    private let failureSubject = PassthroughSubject<PolymarketFastTradingFailure, Never>()
    private var refusalsSubscription: AnyCancellable?
    private var settlingTask: Task<Void, Never>?
    private var operations: [PolymarketFastTradingOperation] = []
    private var lastSnapshot: PolymarketFastTradingSnapshot?
    private var settlingKeyMisses: [String: Int] = [:]
    private var readGeneration = 0
    private var failureSubscriptions = 0
    private var undeliveredFailure: PolymarketFastTradingFailure?

    init(
        userWalletId: UserWalletId,
        manager: PolymarketSessionKeyManaging,
        keyStore: PolymarketSessionKeyStore,
        deviceIdProvider: PolymarketDeviceIdProviding,
        clobService: PolymarketCLOBService,
        credentialsRepository: PolymarketCredentialsRepository,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        bannerDismissals: PolymarketFastTradingBannerDismissals,
        refusalsPublisher: AnyPublisher<Void, Never>,
        pollDelayProvider: PollDelayProvider = TaskSleepPollDelayProvider(),
        now: @escaping () -> Date = Date.init
    ) {
        self.userWalletId = userWalletId
        self.manager = manager
        self.keyStore = keyStore
        self.deviceIdProvider = deviceIdProvider
        self.clobService = clobService
        self.credentialsRepository = credentialsRepository
        self.ownerAddressProvider = ownerAddressProvider
        self.bannerDismissals = bannerDismissals
        self.pollDelayProvider = pollDelayProvider
        self.now = now

        refusalsSubscription = refusalsPublisher
            .sink { [weak self] in
                guard let self else { return }

                Task { await self.refresh() }
            }
    }
}

// MARK: - PolymarketFastTradingServicing protocol conformance

extension CommonPolymarketFastTradingService: PolymarketFastTradingServicing {
    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var state: PolymarketFastTradingState {
        stateSubject.value
    }

    func bannerPublisher(includingForeignSigners: Bool) -> AnyPublisher<PolymarketFastTradingBanner?, Never> {
        stateSubject
            .combineLatest(dismissalsSubject)
            .map { [weak self] state, _ in self?.banner(for: state, includingForeignSigners: includingForeignSigners) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var failurePublisher: AnyPublisher<PolymarketFastTradingFailure, Never> {
        Deferred { [weak self] () -> AnyPublisher<PolymarketFastTradingFailure, Never> in
            guard let self else {
                return Empty().eraseToAnyPublisher()
            }

            return failuresIncludingUndelivered()
        }
        .eraseToAnyPublisher()
    }

    func refresh() async {
        readGeneration += 1
        let generation = readGeneration

        do {
            let snapshot = try await readSnapshot()

            guard generation == readGeneration else { return }

            followSettling(publish(snapshot))
        } catch is CancellationError, PolymarketSessionKeyError.cancelled {
            guard generation == readGeneration else { return }

            publishOperations()
        } catch {
            guard generation == readGeneration else { return }

            PolymarketLogger.error(error: "Failed to read the fast trading state: \(Self.logDescription(of: error))")

            if case .loading = stateSubject.value {
                stateSubject.send(.failed)
            } else {
                publishOperations()

                if case .loaded(let assessment) = stateSubject.value {
                    followSettling(assessment)
                }
            }
        }
    }

    func enable() async throws {
        let manager = manager
        try await performAfterSigning(.activation) { onSigned in
            try await manager.enable(onSigned: onSigned)
        }
    }

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws {
        do {
            try await perform(.activation) {
                try await self.manager.authorize(presigned: batch, grant: grant)
            }
        } catch {
            report(error)
            throw error
        }
    }

    func renew() async throws {
        let manager = manager
        try await performAfterSigning(.activation) { onSigned in
            try await manager.renew(onSigned: onSigned)
        }
    }

    func replace(previous: PolymarketSessionKey, revokesPrevious: Bool) async throws {
        let manager = manager
        try await performAfterSigning(.activation) { onSigned in
            try await manager.replace(previousSessionKeyAddress: previous.address, revokesPrevious: revokesPrevious, onSigned: onSigned)
        }
    }

    func revoke(sessionKeyAddress: String) async throws {
        try await perform(.revocation) { try await self.manager.revoke(sessionKeyAddress: sessionKeyAddress) }
    }

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws {
        try await perform(.toggle) { try await self.manager.setEnabled(isEnabled, sessionKeyAddress: sessionKeyAddress) }
    }

    func dismissBanner(_ banner: PolymarketFastTradingBanner) {
        guard let kind = banner.dismissibleKind else { return }

        bannerDismissals.setDismissalDate(now(), of: kind, userWalletId: userWalletId)
        dismissalsSubject.value += 1
    }
}

// MARK: - Operations

private extension CommonPolymarketFastTradingService {
    func perform(_ operation: PolymarketFastTradingOperation, _ work: () async throws -> PolymarketSessionKey) async throws {
        begin(operation)

        let sessionKey: PolymarketSessionKey

        do {
            sessionKey = try await work()
        } catch {
            await end(operation)
            throw error
        }

        record(sessionKey)
        await end(operation)
    }

    func performAfterSigning(
        _ operation: PolymarketFastTradingOperation,
        _ work: @escaping (_ onSigned: @escaping @Sendable () -> Void) async throws -> PolymarketSessionKey
    ) async throws {
        let handoff = SigningHandoff()

        begin(operation)

        Task { [weak self] in
            do {
                let sessionKey = try await work { handoff.resolve(with: .success(())) }
                handoff.resolve(with: .success(()))
                self?.record(sessionKey)
            } catch {
                if !handoff.resolve(with: .failure(error)) {
                    self?.report(error)
                }
            }

            await self?.end(operation)
        }

        try await handoff.wait()
    }

    func begin(_ operation: PolymarketFastTradingOperation) {
        operations.append(operation)
        publishOperations()
    }

    func end(_ operation: PolymarketFastTradingOperation) async {
        if let index = operations.firstIndex(of: operation) {
            operations.remove(at: index)
        }

        await refresh()
    }

    func publishOperations() {
        guard case .loaded(let published) = stateSubject.value, published.operations != operations, var snapshot = lastSnapshot else {
            return
        }

        snapshot.operations = operations
        stateSubject.send(.loaded(PolymarketFastTradingAssessment(snapshot: snapshot)))
    }

    func record(_ sessionKey: PolymarketSessionKey) {
        guard let snapshot = lastSnapshot else { return }

        let address = sessionKey.address.lowercased()
        let isListed = snapshot.sessionKeys.contains { $0.address == address }
        let sessionKeys = isListed
            ? snapshot.sessionKeys.map { $0.address == address ? sessionKey : $0 }
            : snapshot.sessionKeys + [sessionKey]

        lastSnapshot = PolymarketFastTradingSnapshot(
            sessionKeys: sessionKeys,
            localKeyAddress: snapshot.localKeyAddress,
            deviceId: snapshot.deviceId,
            signers: snapshot.signers,
            now: snapshot.now,
            operations: snapshot.operations
        )
    }

    func report(_ error: Error) {
        PolymarketLogger.error("A signed fast trading operation did not go through", error: error)

        guard let failure = PolymarketFastTradingFailure(error: error) else {
            return
        }

        guard failureSubscriptions > 0 else {
            undeliveredFailure = failure
            return
        }

        failureSubject.send(failure)
    }

    func failuresIncludingUndelivered() -> AnyPublisher<PolymarketFastTradingFailure, Never> {
        let undelivered = undeliveredFailure
        undeliveredFailure = nil

        return failureSubject
            .prepend(undelivered.map { [$0] } ?? [])
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.failureSubscriptions += 1 },
                receiveCancel: { [weak self] in self?.failureSubscriptions -= 1 }
            )
            .eraseToAnyPublisher()
    }

    func banner(for state: PolymarketFastTradingState, includingForeignSigners: Bool) -> PolymarketFastTradingBanner? {
        let date = now()

        return PolymarketFastTradingBanner(state: state, includingForeignSigners: includingForeignSigners) { kind in
            kind.isDismissed(dismissedAt: bannerDismissals.dismissalDate(of: kind, userWalletId: userWalletId), now: date)
        }
    }
}

// MARK: - Assessment

private extension CommonPolymarketFastTradingService {
    func readSnapshot() async throws -> PolymarketFastTradingSnapshot {
        let sessionKeys = try await manager.sessionKeys()
        let signers = try await signers()
        let localKeyAddress = try keyStore.heldAddress(for: userWalletId)
        let deviceId = try deviceIdProvider.deviceId()

        return PolymarketFastTradingSnapshot(
            sessionKeys: sessionKeys,
            localKeyAddress: localKeyAddress,
            deviceId: deviceId,
            signers: signers,
            now: now()
        )
    }

    func publish(_ read: PolymarketFastTradingSnapshot) -> PolymarketFastTradingAssessment {
        let snapshot = PolymarketFastTradingSnapshot(
            sessionKeys: bridgingVanishedSettlingKeys(read.sessionKeys),
            localKeyAddress: read.localKeyAddress,
            deviceId: read.deviceId,
            signers: read.signers,
            now: read.now,
            operations: operations
        )

        lastSnapshot = snapshot

        let assessment = PolymarketFastTradingAssessment(snapshot: snapshot)
        stateSubject.send(.loaded(assessment))

        return assessment
    }

    func bridgingVanishedSettlingKeys(_ sessionKeys: [PolymarketSessionKey]) -> [PolymarketSessionKey] {
        let listed = Set(sessionKeys.map(\.address))
        let previouslySettling = (lastSnapshot?.sessionKeys ?? []).filter { $0.status.isSettling }

        var bridged: [PolymarketSessionKey] = []
        var misses: [String: Int] = [:]

        for sessionKey in previouslySettling where !listed.contains(sessionKey.address) {
            let count = settlingKeyMisses[sessionKey.address, default: 0] + 1

            guard count <= PolymarketSessionKey.settlingMissTolerance else {
                continue
            }

            misses[sessionKey.address] = count
            bridged.append(sessionKey)
        }

        settlingKeyMisses = misses

        return sessionKeys + bridged
    }

    func signers() async throws -> [PolymarketSessionSigner]? {
        guard
            let ownerAddress = ownerAddressProvider.getOwnerAddress(),
            let credentials = credentialsRepository.load(userWalletId: userWalletId)
        else {
            return nil
        }

        do {
            return try await clobService.sessionSigners(credentials: credentials, ownerAddress: ownerAddress)
        } catch let error where error.isCancellationError || Task.isCancelled {
            throw CancellationError()
        } catch {
            PolymarketLogger.error("Failed to read the exchange's session signers", error: error)
            return nil
        }
    }

    func followSettling(_ assessment: PolymarketFastTradingAssessment) {
        guard assessment.hasSettlingChange, settlingTask == nil else {
            return
        }

        settlingTask = Task { [weak self] in
            for _ in 0 ..< Constants.settlingRefreshes {
                guard let self else { return }

                try? await pollDelayProvider.wait(for: Constants.settlingInterval)

                guard !Task.isCancelled else { return }

                await refresh()

                guard case .loaded(let latest) = state, latest.hasSettlingChange else {
                    break
                }
            }

            self?.settlingTask = nil
        }
    }

    enum Constants {
        static let settlingInterval: TimeInterval = 3
        static let settlingRefreshes = 100
    }
}

// MARK: - Logging

private extension CommonPolymarketFastTradingService {
    static func logDescription(of error: Error) -> String {
        switch error {
        case PolymarketSessionKeyError.refused(let statusCode, let reason, _):
            "refused with \(statusCode), \(reason)"
        case PolymarketSessionKeyError.other(.http(let statusCode, _)):
            "HTTP \(statusCode)"
        case PolymarketSessionKeyError.other(.connection(let underlying)):
            "connection error \(underlying.networkErrorCode?.rawValue ?? (underlying as NSError).code)"
        case PolymarketSessionKeyError.other(.decoding(let field, _)):
            "unreadable \(field)"
        default:
            "\(error)"
        }
    }
}

// MARK: - Signing handoff

private extension CommonPolymarketFastTradingService {
    final class SigningHandoff: Sendable {
        private let state = OSAllocatedUnfairLock(initialState: State())

        func wait() async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let outcome = state.withLock { state -> Result<Void, Error>? in
                    if let outcome = state.outcome {
                        return outcome
                    }

                    state.continuation = continuation
                    return nil
                }

                if let outcome {
                    continuation.resume(with: outcome)
                }
            }
        }

        @discardableResult
        func resolve(with outcome: Result<Void, Error>) -> Bool {
            let resolution = state.withLock { state -> (isFirst: Bool, continuation: CheckedContinuation<Void, Error>?) in
                guard state.outcome == nil else {
                    return (false, nil)
                }

                state.outcome = outcome
                defer { state.continuation = nil }

                return (true, state.continuation)
            }

            resolution.continuation?.resume(with: outcome)

            return resolution.isFirst
        }

        private struct State {
            var outcome: Result<Void, Error>?
            var continuation: CheckedContinuation<Void, Error>?
        }
    }
}
