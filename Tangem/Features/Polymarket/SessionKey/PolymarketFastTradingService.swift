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
protocol PolymarketFastTradingRevocationReporting: AnyObject {
    var revocationPublisher: AnyPublisher<PolymarketFastTradingRevocation, Never> { get }
}

@MainActor
protocol PolymarketFastTradingServicing: PolymarketFastTradingBannerProviding, PolymarketFastTradingOperating, PolymarketFastTradingFailureReporting,
    PolymarketFastTradingRevocationReporting {
    func cancelWork()
}

enum PolymarketFastTradingRevocation: Equatable {
    case submitted
    case succeeded
    case failed
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
    private let failures = HeldEvents<PolymarketFastTradingFailure>()
    private let revocations = HeldEvents<PolymarketFastTradingRevocation>()
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
    private var revokingSince: [String: Date] = [:]
    private var revocationsInFlight: [String: RevocationEvidence] = [:]

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
            self?.failures.publisher() ?? .empty
        }
        .eraseToAnyPublisher()
    }

    var revocationPublisher: AnyPublisher<PolymarketFastTradingRevocation, Never> {
        Deferred { [weak self] () -> AnyPublisher<PolymarketFastTradingRevocation, Never> in
            self?.revocations.publisher() ?? .empty
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
        try await perform(.activation) {
            try await self.manager.authorize(presigned: batch, grant: grant)
        }

        forgetBannerDismissals()
    }

    func revoke(sessionKeyAddress: String) async throws {
        let address = sessionKeyAddress.lowercased()
        let hasLiveRecord = lastSnapshot?.sessionKeys.contains { $0.address == address && $0.isOurs } ?? false

        do {
            try await perform(.revocation) { try await self.manager.revoke(sessionKeyAddress: sessionKeyAddress) }
        } catch {
            switch PolymarketFastTradingFailure(error: error) {
            case .busy:
                failures.send(.busy)
            case .some:
                revocations.send(.failed)
            case nil:
                break
            }

            throw error
        }

        revocations.send(.submitted)
        revocationsInFlight[address] = hasLiveRecord ? .records : .signers
        reportSettledRevocations()
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
        failures.send(failure)
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
                        await reportAuthorizationFailureUnlessKeptForResend(error, of: operation)
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
        noteRevoking(by: interrupted)

        do {
            try await finish(interrupted)
        } catch PolymarketSessionKeyManagerError.operationInProgress {
            PolymarketLogger.warning("The wallet is busy with another operation, the interrupted fast trading authorization waits for a retry")
            scheduleResumeRetry(of: interrupted, after: PolymarketSessionKeyManagerError.operationInProgress)
            return
        } catch where PolymarketInterruptedAuthorization.isResumable(after: error) {
            PolymarketLogger.warning("An interrupted fast trading authorization could not be completed yet, it stays kept")
            scheduleResumeRetry(of: interrupted, after: error)
            return
        } catch {
            return
        }

        if await manager.resumableInterruptedAuthorization()?.batch == interrupted.batch {
            scheduleResumeRetry(of: interrupted, after: nil)
        }
    }

    func finish(_ interrupted: PolymarketInterruptedAuthorization) async throws {
        let manager = manager

        do {
            try await perform(interrupted.operation) { try await manager.resumeInterruptedAuthorization() }
            forgetBannerDismissals()
        } catch PolymarketSessionKeyManagerError.noInterruptedAuthorization {
            PolymarketLogger.warning("There is no interrupted fast trading authorization left to send")
            reportAuthorizationFailure(PolymarketSessionKeyManagerError.noInterruptedAuthorization, of: interrupted.operation)
        } catch where Self.endsTheResume(error) {
            reportAuthorizationFailure(error, of: interrupted.operation)
            stopResuming(interrupted.batch)
            throw error
        }
    }

    func stopResuming(_ batch: PolymarketRelayedBatch) {
        PolymarketLogger.warning("An interrupted fast trading authorization is not sent again on its own, it stays kept until it runs out")

        resumeAttempts = ResumeAttempts(batch: batch, count: Constants.resumeAttemptLimit, isDue: false)
    }

    func scheduleResumeRetry(of interrupted: PolymarketInterruptedAuthorization, after failure: Error?) {
        let batch = interrupted.batch

        guard resumeRetryTask == nil, let attempts = resumeAttempts, attempts.batch == batch else {
            return
        }

        guard attempts.count < Constants.resumeAttemptLimit else {
            PolymarketLogger.warning("An interrupted fast trading authorization ran out of resume attempts, it stays kept until it runs out")

            if let failure {
                reportAuthorizationFailure(failure, of: interrupted.operation)
            }

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
            revokingSince: revokingSince
        )
    }

    func isRefused(_ localKeyAddress: String?) -> Bool {
        localKeyAddress.map(signingRouter.isRefused(sessionKeyAddress:)) ?? false
    }

    func forgetBannerDismissals() {
        bannerDismissals.deleteDismissals(userWalletId: userWalletId)
        dismissalDatesSubject.send(bannerDismissals.dismissalDates(userWalletId: userWalletId))
    }

    func reportAuthorizationFailureUnlessKeptForResend(_ error: Error, of operation: PolymarketFastTradingOperation) async {
        guard let kept = await manager.resumableInterruptedAuthorization() else {
            reportAuthorizationFailure(error, of: operation)
            return
        }

        noteRevoking(by: kept)
        PolymarketLogger.warning("A signed fast trading operation did not go through yet, it is kept for a resend: \(PolymarketFastTradingFailure.logDescription(of: error))")
    }

    func reportAuthorizationFailure(_ error: Error, of operation: PolymarketFastTradingOperation) {
        PolymarketLogger.error(error: "A signed fast trading operation did not go through: \(PolymarketFastTradingFailure.logDescription(of: error))")

        guard let failure = PolymarketFastTradingFailure(error: error, authorizing: operation) else {
            return
        }

        if operation == .activation {
            forgetBannerDismissals()
        }

        failures.send(failure)
    }

    func reportSettledRevocations() {
        guard let snapshot = lastSnapshot else { return }

        for (address, evidence) in revocationsInFlight {
            guard let outcome = Self.revocationOutcome(of: address, by: evidence, in: snapshot) else { continue }

            revocationsInFlight[address] = nil
            revocations.send(outcome)
        }
    }

    static func revocationOutcome(
        of address: String,
        by evidence: RevocationEvidence,
        in snapshot: PolymarketFastTradingSnapshot
    ) -> PolymarketFastTradingRevocation? {
        let record = snapshot.sessionKeys.revocationRecord(of: address, at: snapshot.now)

        if record?.status.isSettling == true {
            return nil
        }

        if evidence == .records, let record {
            return record.status == .revoked ? .succeeded : .failed
        }

        guard let signers = snapshot.signers else {
            return nil
        }

        guard signers.contains(where: { $0.address == address }) else {
            return .succeeded
        }

        if record != nil, PolymarketFastTradingAssessment.isBeingRevoked(address, in: snapshot) {
            return nil
        }

        return .failed
    }

    enum RevocationEvidence {
        case records
        case signers
    }
}

// MARK: - Held events

@MainActor
private final class HeldEvents<Event> {
    private let subject = PassthroughSubject<Event, Never>()
    private var subscriptions = 0
    private var undelivered: Event?

    func send(_ event: Event) {
        guard subscriptions > 0 else {
            undelivered = event
            return
        }

        subject.send(event)
    }

    func publisher() -> AnyPublisher<Event, Never> {
        let undelivered = undelivered
        self.undelivered = nil

        return subject
            .prepend(undelivered.map { [$0] } ?? [])
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.subscriptions += 1 },
                receiveCancel: { [weak self] in self?.subscriptions -= 1 }
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

        return PolymarketFastTradingSnapshot(
            sessionKeys: sessionKeys,
            localKeyAddress: localKeyAddress,
            deviceId: deviceId,
            signers: signers,
            now: now()
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
            revokingSince: revokingSince
        )

        lastSnapshot = snapshot
        publishedGeneration = generation

        let assessment = PolymarketFastTradingAssessment(snapshot: snapshot)
        stateSubject.send(.loaded(assessment))
        reportSettledRevocations()

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

    func noteRevoking(by interrupted: PolymarketInterruptedAuthorization) {
        let address = interrupted.revokedAddress.lowercased()

        guard interrupted.isExecutable(at: now()), revokingSince[address] == nil else {
            return
        }

        revokingSince[address] = now()
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

private extension PolymarketInterruptedAuthorization {
    var operation: PolymarketFastTradingOperation {
        switch purpose {
        case .activation:
            .activation
        case .renewal:
            .renewal
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
