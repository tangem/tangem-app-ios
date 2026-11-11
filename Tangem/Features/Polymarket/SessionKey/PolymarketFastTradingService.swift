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
protocol PolymarketFastTradingStateProviding: AnyObject {
    var state: PolymarketFastTradingState { get }

    var statePublisher: AnyPublisher<PolymarketFastTradingState, Never> { get }

    func refresh() async
}

@MainActor
protocol PolymarketFastTradingBannerProviding: PolymarketFastTradingStateProviding {
    var bannerDismissalsPublisher: AnyPublisher<PolymarketFastTradingBanner.DismissalDates, Never> { get }

    func dismissBanner(_ banner: PolymarketFastTradingBanner)
}

@MainActor
protocol PolymarketFastTradingOperating: PolymarketFastTradingStateProviding {
    func authorize(_ authorization: PolymarketFastTradingAuthorization) async throws

    func authorize(presigned batch: PolymarketRelayedBatch, grant: PolymarketSessionKeyGrant) async throws

    func revoke(sessionKeyAddress: String) async throws

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws
}

@MainActor
protocol PolymarketFastTradingFailureReporting: AnyObject {
    var failurePublisher: AnyPublisher<PolymarketFastTradingFailure, Never> { get }

    func reportFailure(_ failure: PolymarketFastTradingFailure)
}

@MainActor
protocol PolymarketFastTradingServicing: PolymarketFastTradingBannerProviding, PolymarketFastTradingOperating, PolymarketFastTradingFailureReporting {
    func cancelWork()
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
    private let signingRouter: PolymarketOrderSigningRouting
    private let pollDelayProvider: PollDelayProvider
    private let now: () -> Date

    private let stateSubject = CurrentValueSubject<PolymarketFastTradingState, Never>(.loading)
    private let dismissalDatesSubject: CurrentValueSubject<PolymarketFastTradingBanner.DismissalDates, Never>
    private let failureSubject = PassthroughSubject<PolymarketFastTradingFailure, Never>()
    private var refusalsSubscription: AnyCancellable?
    private var settlingTask: Task<Void, Error>?
    private var resumeRetryTask: Task<Void, Error>?
    private var resumeTask: Task<Void, Never>?
    private var signedOperationTasks: [UUID: Task<Void, Never>] = [:]
    private var resumeAttempts: ResumeAttempts?
    private var operations: [PolymarketFastTradingOperation] = []
    private var lastSnapshot: PolymarketFastTradingSnapshot?
    private var settlingKeyMisses: [String: Int] = [:]
    private var readGeneration = 0
    private var publishedGeneration = 0
    private var failureSubscriptions = 0
    private var undeliveredFailure: PolymarketFastTradingFailure?
    private var revokingSince: [String: Date] = [:]

    init(
        userWalletId: UserWalletId,
        manager: PolymarketSessionKeyManaging,
        keyStore: PolymarketSessionKeyStore,
        deviceIdProvider: PolymarketDeviceIdProviding,
        clobService: PolymarketCLOBService,
        credentialsRepository: PolymarketCredentialsRepository,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        bannerDismissals: PolymarketFastTradingBannerDismissals,
        signingRouter: PolymarketOrderSigningRouting,
        pollDelayProvider: PollDelayProvider = TaskSleepPollDelayProvider(),
        now: @escaping () -> Date = { InjectedValues[\.polymarketServerClock].now }
    ) {
        self.userWalletId = userWalletId
        self.manager = manager
        self.keyStore = keyStore
        self.deviceIdProvider = deviceIdProvider
        self.clobService = clobService
        self.credentialsRepository = credentialsRepository
        self.ownerAddressProvider = ownerAddressProvider
        self.bannerDismissals = bannerDismissals
        self.signingRouter = signingRouter
        self.pollDelayProvider = pollDelayProvider
        self.now = now

        dismissalDatesSubject = CurrentValueSubject(bannerDismissals.dismissalDates(userWalletId: userWalletId))

        refusalsSubscription = signingRouter.refusalsPublisher
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

    var bannerDismissalsPublisher: AnyPublisher<PolymarketFastTradingBanner.DismissalDates, Never> {
        dismissalDatesSubject.eraseToAnyPublisher()
    }

    var failurePublisher: AnyPublisher<PolymarketFastTradingFailure, Never> {
        Deferred { [weak self] () -> AnyPublisher<PolymarketFastTradingFailure, Never> in
            guard let self else {
                return .empty
            }

            return failuresIncludingUndelivered()
        }
        .eraseToAnyPublisher()
    }

    func refresh() async {
        readGeneration += 1
        let generation = readGeneration
        let publishedBeforeRead = publishedGeneration
        let readStartedAt = now()
        let read: Result<PolymarketFastTradingSnapshot, Error>

        do {
            read = try await .success(readSnapshot())
        } catch {
            read = .failure(error)
        }

        guard generation > publishedGeneration else { return }

        switch read {
        case .success(let snapshot):
            await forgetRefusal(confirmedBy: snapshot, readStartedAt: readStartedAt)

            guard generation > publishedGeneration else { return }

            followSettling(publish(snapshot, generation: generation, countsMisses: publishedGeneration == publishedBeforeRead))
            resumeInterruptedAuthorizationIfNeeded()
        case .failure(let error):
            handleFailedRead(error)
        }
    }

    func cancelWork() {
        resumeTask?.cancel()
        resumeRetryTask?.cancel()
        settlingTask?.cancel()
        signedOperationTasks.values.forEach { $0.cancel() }
    }

    func authorize(_ authorization: PolymarketFastTradingAuthorization) async throws {
        let manager = manager
        try await performAfterSigning(authorization.operation) { onSigned in
            try await manager.authorize(authorization, onSigned: onSigned)
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

        forgetBannerDismissals()
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
        dismissalDatesSubject.send(bannerDismissals.dismissalDates(userWalletId: userWalletId))
    }

    func reportFailure(_ failure: PolymarketFastTradingFailure) {
        deliver(failure)
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
        begin(operation)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let handoff = ResumableOnceCheckedContinuationWrapper(continuation)
            let taskId = UUID()

            signedOperationTasks[taskId] = Task { @MainActor [self] in
                defer { signedOperationTasks[taskId] = nil }

                do {
                    let sessionKey = try await work { handoff.resumeIfNeeded() }
                    handoff.resumeIfNeeded()
                    record(sessionKey)
                    forgetBannerDismissals()
                } catch {
                    if !handoff.resumeIfNeeded(with: .failure(error)) {
                        report(error)
                    }
                }

                await end(operation)
            }
        }
    }

    func resumeInterruptedAuthorizationIfNeeded() {
        guard resumeTask == nil, operations.isEmpty else {
            return
        }

        resumeTask = Task { [self] in
            if let interrupted = await manager.resumableInterruptedAuthorization(), operations.isEmpty, startResumeAttempt(of: interrupted.batch) {
                await resume(interrupted)
            }

            resumeTask = nil
        }
    }

    func startResumeAttempt(of batch: PolymarketRelayedBatch) -> Bool {
        var attempts = resumeAttempts.flatMap { $0.batch == batch ? $0 : nil } ?? ResumeAttempts(batch: batch)

        guard attempts.isDue, attempts.count < Constants.resumeAttemptLimit else {
            return false
        }

        attempts.count += 1
        attempts.isDue = false
        resumeAttempts = attempts

        return true
    }

    func resume(_ interrupted: PolymarketInterruptedAuthorization) async {
        do {
            try await finish(interrupted)
        } catch PolymarketSessionKeyManagerError.operationInProgress {
            PolymarketLogger.warning("The wallet is busy with another operation, the interrupted fast trading authorization waits for a retry")
            scheduleResumeRetry(of: interrupted.batch)
            return
        } catch where PolymarketInterruptedAuthorization.isResumable(after: error) {
            PolymarketLogger.warning("An interrupted fast trading authorization could not be completed yet, it stays kept")
            scheduleResumeRetry(of: interrupted.batch)
            return
        } catch {
            return
        }

        if await manager.resumableInterruptedAuthorization()?.batch == interrupted.batch {
            scheduleResumeRetry(of: interrupted.batch)
        }
    }

    func finish(_ interrupted: PolymarketInterruptedAuthorization) async throws {
        let manager = manager

        do {
            try await perform(interrupted.operation) { try await manager.resumeInterruptedAuthorization() }
            forgetBannerDismissals()
        } catch PolymarketSessionKeyManagerError.noInterruptedAuthorization {
            PolymarketLogger.warning("There is no interrupted fast trading authorization left to send")
        } catch where Self.endsTheResume(error) {
            report(error)
            stopResuming(interrupted.batch)
            throw error
        }
    }

    func stopResuming(_ batch: PolymarketRelayedBatch) {
        PolymarketLogger.warning("An interrupted fast trading authorization is not sent again on its own, it stays kept until it runs out")

        resumeAttempts = ResumeAttempts(batch: batch, count: Constants.resumeAttemptLimit, isDue: false)
    }

    func scheduleResumeRetry(of batch: PolymarketRelayedBatch) {
        guard resumeRetryTask == nil, let attempts = resumeAttempts, attempts.batch == batch else {
            return
        }

        guard attempts.count < Constants.resumeAttemptLimit else {
            PolymarketLogger.warning("An interrupted fast trading authorization ran out of resume attempts, it stays kept until it runs out")
            return
        }

        let delay = Constants.resumeRetryDelay * pow(2, Double(max(attempts.count - 1, 0)))

        resumeRetryTask = Task { [weak self, pollDelayProvider] in
            try await pollDelayProvider.wait(for: delay)

            guard let self else { return }

            resumeRetryTask = nil

            if resumeAttempts?.batch == batch {
                resumeAttempts?.isDue = true
            }

            await refresh()
            resumeInterruptedAuthorizationIfNeeded()
        }
    }

    static func endsTheResume(_ error: Error) -> Bool {
        switch error {
        case PolymarketSessionKeyManagerError.operationInProgress:
            false
        default:
            !PolymarketInterruptedAuthorization.isResumable(after: error)
        }
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
        resumeInterruptedAuthorizationIfNeeded()
    }

    @discardableResult
    func publishOperations() -> PolymarketFastTradingAssessment? {
        guard case .loaded(let published) = stateSubject.value else {
            return nil
        }

        guard var snapshot = lastSnapshot else {
            return published
        }

        snapshot.operations = operations
        snapshot.isLocalKeyRefused = isRefused(snapshot.localKeyAddress)

        let assessment = PolymarketFastTradingAssessment(snapshot: snapshot)

        guard assessment != published else {
            return published
        }

        stateSubject.send(.loaded(assessment))

        return assessment
    }

    func record(_ sessionKey: PolymarketSessionKey) {
        let address = sessionKey.address.lowercased()

        publishedGeneration = readGeneration

        if sessionKey.status == .revoking || sessionKey.status == .revoked, revokingSince[address] == nil {
            revokingSince[address] = now()
        }

        guard let snapshot = lastSnapshot else { return }

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
            operations: snapshot.operations,
            isLocalKeyRefused: isRefused(snapshot.localKeyAddress),
            revokingSince: revokingSince,
            keptPausedKeyAddress: snapshot.keptPausedKeyAddress
        )
    }

    func isRefused(_ localKeyAddress: String?) -> Bool {
        localKeyAddress.map(signingRouter.isRefused(sessionKeyAddress:)) ?? false
    }

    func forgetBannerDismissals() {
        bannerDismissals.deleteDismissals(userWalletId: userWalletId)
        dismissalDatesSubject.send(bannerDismissals.dismissalDates(userWalletId: userWalletId))
    }

    func report(_ error: Error) {
        PolymarketLogger.error(error: "A signed fast trading operation did not go through: \(PolymarketFastTradingFailure.logDescription(of: error))")

        guard let failure = PolymarketFastTradingFailure(error: error) else {
            return
        }

        deliver(failure)
    }

    func deliver(_ failure: PolymarketFastTradingFailure) {
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
}

// MARK: - Resume attempts

private extension CommonPolymarketFastTradingService {
    struct ResumeAttempts {
        let batch: PolymarketRelayedBatch
        var count = 0
        var isDue = true
    }
}

// MARK: - Assessment

private extension CommonPolymarketFastTradingService {
    func readSnapshot() async throws -> PolymarketFastTradingSnapshot {
        let sessionKeys = try await manager.sessionKeys()
        let signers = try await signers()
        let localKeyAddress = try keyStore.heldAddress(for: userWalletId)
        let deviceId = try deviceIdProvider.deviceId()
        let keptPausedKeyAddress = await manager.keptPausedKeyAddress()

        return PolymarketFastTradingSnapshot(
            sessionKeys: sessionKeys,
            localKeyAddress: localKeyAddress,
            deviceId: deviceId,
            signers: signers,
            now: now(),
            keptPausedKeyAddress: keptPausedKeyAddress
        )
    }

    func forgetRefusal(confirmedBy snapshot: PolymarketFastTradingSnapshot, readStartedAt: Date) async {
        guard
            let localKeyAddress = snapshot.localKeyAddress,
            let refusal = signingRouter.refusal(of: localKeyAddress),
            refusal.refusedAt < readStartedAt,
            PolymarketFastTradingAssessment.confirmsLocalKey(after: refusal, in: snapshot)
        else {
            return
        }

        await signingRouter.invalidate(sessionKeyAddress: localKeyAddress)
    }

    func handleFailedRead(_ error: Error) {
        let isCancellation = PolymarketSessionKeyError.isCancellation(error)

        if !isCancellation {
            PolymarketLogger.error(error: "Failed to read the fast trading state: \(PolymarketFastTradingFailure.logDescription(of: error))")
        }

        switch stateSubject.value {
        case .loading:
            if !isCancellation {
                stateSubject.send(.failed)
            }
        case .loaded:
            if let assessment = publishOperations() {
                followSettling(assessment)
            }
        case .failed:
            break
        }
    }

    func publish(_ read: PolymarketFastTradingSnapshot, generation: Int, countsMisses: Bool) -> PolymarketFastTradingAssessment {
        let sessionKeys = bridgingVanishedSettlingKeys(read.sessionKeys, countsMisses: countsMisses)
        noteRevoking(in: sessionKeys, at: read.now)

        let snapshot = PolymarketFastTradingSnapshot(
            sessionKeys: sessionKeys,
            localKeyAddress: read.localKeyAddress,
            deviceId: read.deviceId,
            signers: read.signers,
            now: read.now,
            operations: operations,
            isLocalKeyRefused: isRefused(read.localKeyAddress),
            revokingSince: revokingSince,
            keptPausedKeyAddress: read.keptPausedKeyAddress
        )

        lastSnapshot = snapshot
        publishedGeneration = generation

        let assessment = PolymarketFastTradingAssessment(snapshot: snapshot)
        stateSubject.send(.loaded(assessment))

        return assessment
    }

    func noteRevoking(in sessionKeys: [PolymarketSessionKey], at date: Date) {
        let revoking = Set(sessionKeys.filter { $0.status == .revoking }.map { $0.address.lowercased() })

        revokingSince = revokingSince.filter { address, since in
            revoking.contains(address) || date.timeIntervalSince(since) < PolymarketSessionKey.backendHoldWindow
        }

        for address in revoking where revokingSince[address] == nil {
            revokingSince[address] = date
        }
    }

    func bridgingVanishedSettlingKeys(_ sessionKeys: [PolymarketSessionKey], countsMisses: Bool) -> [PolymarketSessionKey] {
        let listed = Set(sessionKeys.map(\.address))
        let previouslySettling = lastSnapshot.map(PolymarketFastTradingAssessment.settlingKeys(in:)) ?? []

        var bridged: [PolymarketSessionKey] = []
        var misses: [String: Int] = [:]

        for sessionKey in previouslySettling where !listed.contains(sessionKey.address) {
            let previousMisses = settlingKeyMisses[sessionKey.address, default: 0]
            let count = countsMisses ? previousMisses + 1 : previousMisses

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
        guard assessment.needsFollowUpReads, settlingTask == nil else {
            return
        }

        settlingTask = Task { [weak self, pollDelayProvider] in
            defer { self?.settlingTask = nil }

            for read in 0 ..< Constants.settlingReads {
                try await pollDelayProvider.wait(for: Constants.settlingInterval(beforeRead: read))

                await self?.refresh()

                guard case .loaded(let latest)? = self?.state, latest.needsFollowUpReads else {
                    return
                }
            }
        }
    }

    enum Constants {
        static let settlingInterval: TimeInterval = 3
        static let slowSettlingInterval: TimeInterval = 20
        static let fastSettlingPhase: TimeInterval = 2 * 60
        static let fastSettlingReads = Int((fastSettlingPhase / settlingInterval).rounded(.up))
        static let slowSettlingReads = Int(((PolymarketSessionKey.backendHoldWindow - fastSettlingPhase) / slowSettlingInterval).rounded(.up))
        static let settlingReads = fastSettlingReads + slowSettlingReads

        static let resumeRetryDelay: TimeInterval = 10
        static let resumeAttemptLimit = 3

        static func settlingInterval(beforeRead read: Int) -> TimeInterval {
            read < fastSettlingReads ? settlingInterval : slowSettlingInterval
        }
    }
}

// MARK: - Authorization

private extension PolymarketFastTradingAuthorization {
    var operation: PolymarketFastTradingOperation {
        switch self {
        case .enable, .reenable, .repair, .replace:
            .activation
        case .renew:
            .renewal
        }
    }
}

private extension PolymarketInterruptedAuthorization {
    var operation: PolymarketFastTradingOperation {
        guard !isExecuted else {
            return .toggle
        }

        switch purpose {
        case .activation:
            return .activation
        case .renewal:
            return .renewal
        }
    }
}

private extension PolymarketSessionKeyManaging {
    func authorize(
        _ authorization: PolymarketFastTradingAuthorization,
        onSigned: @escaping @Sendable () -> Void
    ) async throws -> PolymarketSessionKey {
        switch authorization {
        case .enable, .reenable:
            try await enable(onSigned: onSigned)
        case .renew:
            try await renew(onSigned: onSigned)
        case .repair:
            try await repair(onSigned: onSigned)
        case .replace(let previous, let revokesPrevious):
            try await replace(previousSessionKeyAddress: previous.address, revokesPrevious: revokesPrevious, onSigned: onSigned)
        }
    }
}
