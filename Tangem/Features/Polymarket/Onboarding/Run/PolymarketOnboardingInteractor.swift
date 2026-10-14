//
//  PolymarketOnboardingInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketOnboardingInteractor {
    func onboard() -> AsyncStream<PolymarketOnboardingProgress>
}

final class CommonPolymarketOnboardingInteractor {
    private let userWalletId: UserWalletId
    private let ownerAddressProvider: PolymarketOwnerAddressProviding
    private let ownerKeySession: PolymarketOwnerKeySession
    private let signer: PolymarketOnboardingSigning
    private let credentialsRepository: PolymarketCredentialsRepository
    private let geoblockService: PolymarketGeoblockService
    private let walletService: PolymarketDepositWalletService
    private let relayerService: PolymarketRelayerService
    private let clobService: PolymarketCLOBService
    private let serverClock: PolymarketServerClock
    private let pollInterval: TimeInterval

    init(
        userWalletId: UserWalletId,
        ownerAddressProvider: PolymarketOwnerAddressProviding,
        ownerKeySession: PolymarketOwnerKeySession,
        signer: PolymarketOnboardingSigning,
        credentialsRepository: PolymarketCredentialsRepository,
        geoblockService: PolymarketGeoblockService,
        walletService: PolymarketDepositWalletService,
        relayerService: PolymarketRelayerService,
        clobService: PolymarketCLOBService,
        serverClock: PolymarketServerClock,
        pollInterval: TimeInterval = PolymarketDepositWalletPoller.Constants.interval
    ) {
        self.userWalletId = userWalletId
        self.ownerAddressProvider = ownerAddressProvider
        self.ownerKeySession = ownerKeySession
        self.signer = signer
        self.credentialsRepository = credentialsRepository
        self.geoblockService = geoblockService
        self.walletService = walletService
        self.relayerService = relayerService
        self.clobService = clobService
        self.serverClock = serverClock
        self.pollInterval = pollInterval
    }
}

// MARK: - PolymarketOnboardingInteractor protocol conformance

extension CommonPolymarketOnboardingInteractor: PolymarketOnboardingInteractor {
    func onboard() -> AsyncStream<PolymarketOnboardingProgress> {
        AsyncStream { continuation in
            let task = Task {
                await onboard(reporting: continuation)
                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

// MARK: - The run

private extension CommonPolymarketOnboardingInteractor {
    func ensureRegionAllows(status: PolymarketDepositWalletStatus) async throws {
        guard status.owesApprovals else { return }

        do {
            let geoblock = try await geoblockService.geoblock()

            guard !geoblock.isBlocked else { throw PolymarketOnboardingError.regionBlocked }
        } catch let error as PolymarketOnboardingError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            PolymarketLogger.error("The region could not be read, refusing to onboard", error: error)
            throw PolymarketOnboardingError.regionUnknown
        }
    }

    func onboard(reporting continuation: PolymarketOnboardingContinuation) async {
        do {
            continuation.yield(.deriving)

            let preparation: Preparation

            if let ownerAddress = ownerAddressProvider.getOwnerAddress() {
                preparation = try await prepareWithStoredKey(ownerAddress: ownerAddress, reporting: continuation)
            } else {
                preparation = try await prepareInOwnerKeySession(reporting: continuation)
            }

            try await complete(preparation, reporting: continuation)
        } catch let error as PolymarketOnboardingError {
            guard !error.isCancellation else { return }

            continuation.yield(.failed(error))
        } catch is CancellationError {
            return
        } catch {
            PolymarketLogger.error("The onboarding run failed", error: error)
            continuation.yield(.failed(.unknown))
        }
    }

    func prepareWithStoredKey(
        ownerAddress: String,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws -> Preparation {
        let addresses = try makeAddresses(ownerAddress: ownerAddress)
        var status = try await readStatus(addresses: addresses)

        if status == .unknown {
            switch try await makePoller(addresses: addresses).pollUntilRecognised(from: status, reporting: continuation) {
            case .reached(let recognised):
                status = recognised
            case .ceiling(let reported):
                return .handedOff(reported)
            }
        }

        return try await prepareSignatures(addresses: addresses, status: status, signer: signer, reporting: continuation)
    }

    func prepareInOwnerKeySession(reporting continuation: PolymarketOnboardingContinuation) async throws -> Preparation {
        try await ownerKeySession.derive { [self] owner in
            let addresses = try makeAddresses(ownerAddress: owner.ownerAddress)
            let status = try await readStatus(addresses: addresses)

            guard status != .unknown else {
                PolymarketLogger.error(error: "The backend reports an unrecognised status, ending the owner key session")
                throw PolymarketOnboardingError.wallet(.upstreamUnavailable(detail: nil))
            }

            return try await prepareSignatures(
                addresses: addresses,
                status: status,
                signer: owner.signer,
                reporting: continuation
            )
        }
    }

    func prepareSignatures(
        addresses: Addresses,
        status: PolymarketDepositWalletStatus,
        signer: PolymarketOnboardingSigning,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws -> Preparation {
        let account = Account(
            addresses: addresses,
            status: status,
            storedCredentials: credentialsRepository.load(userWalletId: userWalletId)
        )

        if !status.owesApprovals, let credentials = account.storedCredentials {
            return .authorised(account, credentials: credentials)
        }

        try await ensureRegionAllows(status: status)

        continuation.yield(.awaitingSignature)

        let signatures = try await sign(addresses: addresses, signer: signer)

        return .signed(account, signatures: signatures)
    }

    func complete(_ preparation: Preparation, reporting continuation: PolymarketOnboardingContinuation) async throws {
        switch preparation {
        case .handedOff(let status):
            continuation.yield(.handedOff(status))
        case .authorised(let account, let credentials):
            try await finish(
                addresses: account.addresses,
                status: account.status,
                credentials: credentials,
                poller: makePoller(addresses: account.addresses),
                isNewAccount: account.isNewAccount,
                reporting: continuation
            )
        case .signed(let account, let signatures):
            try await settle(
                addresses: account.addresses,
                status: account.status,
                storedCredentials: account.storedCredentials,
                signatures: signatures,
                poller: makePoller(addresses: account.addresses),
                isNewAccount: account.isNewAccount,
                reporting: continuation
            )
        }
    }

    func makePoller(addresses: Addresses) -> PolymarketDepositWalletPoller {
        PolymarketDepositWalletPoller(
            walletService: walletService,
            ownerAddress: addresses.owner,
            depositWalletAddress: addresses.depositWallet,
            interval: pollInterval
        )
    }
}

// MARK: - Addresses

private extension CommonPolymarketOnboardingInteractor {
    func makeAddresses(ownerAddress owner: String) throws(PolymarketOnboardingError) -> Addresses {
        do {
            let depositWallet = try PolymarketDepositWalletDeriver.derive(ownerAddress: owner)

            return Addresses(owner: owner, depositWallet: depositWallet)
        } catch {
            PolymarketLogger.error("Failed to derive the deposit wallet", error: error)
            throw .depositWalletDerivation
        }
    }

    struct Addresses {
        let owner: String
        let depositWallet: String
    }
}

// MARK: - Preparation

private extension CommonPolymarketOnboardingInteractor {
    enum Preparation {
        case handedOff(PolymarketDepositWalletStatus)
        case authorised(Account, credentials: PolymarketL2Credentials)
        case signed(Account, signatures: PolymarketOnboardingSignatures)
    }

    struct Account {
        let addresses: Addresses
        let status: PolymarketDepositWalletStatus
        let storedCredentials: PolymarketL2Credentials?

        var isNewAccount: Bool {
            status != .readyToTrade
        }
    }
}

// MARK: - The record on the backend

private extension CommonPolymarketOnboardingInteractor {
    func readDepositWallet(ownerAddress: String) async throws -> PolymarketDepositWallet {
        do {
            return try await walletService.depositWalletState(ownerAddress: ownerAddress)
        } catch {
            throw PolymarketOnboardingError.wallet(error)
        }
    }

    func readStatus(addresses: Addresses) async throws -> PolymarketDepositWalletStatus {
        let stored = try await readDepositWallet(ownerAddress: addresses.owner)
        try stored.ensureMatches(derived: addresses.depositWallet)

        return stored.status
    }
}

// MARK: - Signatures

private extension CommonPolymarketOnboardingInteractor {
    func sign(addresses: Addresses, signer: PolymarketOnboardingSigning) async throws -> PolymarketOnboardingSignatures {
        let nonce: String

        do {
            nonce = try await relayerService.walletNonce(ownerAddress: addresses.owner)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            PolymarketLogger.error("Failed to read the relayer nonce", error: error)
            throw PolymarketOnboardingError.unknown
        }

        let approvals = PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: addresses.depositWallet,
            nonce: nonce,
            deadline: makeDeadline(),
            calls: PolymarketApprovalCalls.make()
        )

        let signatures: PolymarketOnboardingSignatures

        do {
            signatures = try await signer.sign(approvals: approvals)
        } catch {
            throw PolymarketOnboardingError.signing(error)
        }

        guard signatures.approvals.ownerAddress.caseInsensitiveCompare(addresses.owner) == .orderedSame else {
            PolymarketLogger.error(
                "The card signed for \(signatures.approvals.ownerAddress), the run derived \(addresses.owner)",
                error: PolymarketOnboardingError.addressMismatch
            )
            throw PolymarketOnboardingError.addressMismatch
        }

        return signatures
    }

    func makeDeadline() -> String {
        String(Int(serverClock.now.timeIntervalSince1970) + Constants.deadlineOffset)
    }
}

// MARK: - Settle

private extension CommonPolymarketOnboardingInteractor {
    func settle(
        addresses: Addresses,
        status initial: PolymarketDepositWalletStatus,
        storedCredentials: PolymarketL2Credentials?,
        signatures: PolymarketOnboardingSignatures,
        poller: PolymarketDepositWalletPoller,
        isNewAccount: Bool,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws {
        var status = initial

        if status.needsDeploy {
            status = try await deploy(addresses: addresses, reporting: continuation)
        }

        let credentials: PolymarketL2Credentials

        if let storedCredentials {
            credentials = storedCredentials
        } else {
            credentials = try await obtainCredentials(authHeaders: signatures.authHeaders)
        }

        if status.owesApprovals {
            if !status.isDeployComplete {
                let outcome = try await poller.poll(until: .deployed, from: status, reporting: continuation)

                switch outcome {
                case .reached(let deployed):
                    status = deployed
                case .ceiling(let reported):
                    continuation.yield(.handedOff(reported))
                    return
                }
            }

            if status.owesApprovals {
                status = try await submitApprovals(signatures: signatures, reporting: continuation)
            }
        }

        try await finish(
            addresses: addresses,
            status: status,
            credentials: credentials,
            poller: poller,
            isNewAccount: isNewAccount,
            reporting: continuation
        )
    }

    func deploy(
        addresses: Addresses,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws -> PolymarketDepositWalletStatus {
        let status: PolymarketDepositWalletStatus

        do {
            status = try await walletService.deployWallet(
                ownerAddress: addresses.owner,
                depositWalletAddress: addresses.depositWallet
            )
        } catch {
            guard !error.isConflict else {
                PolymarketLogger.error(error: "The wallet id is already bound to another owner")
                throw PolymarketOnboardingError.walletIdTaken
            }

            throw PolymarketOnboardingError.wallet(error)
        }

        guard status != .deploymentFailed else {
            throw PolymarketOnboardingError.deploymentFailed
        }

        continuation.yield(.working(status))

        return status
    }

    func submitApprovals(
        signatures: PolymarketOnboardingSignatures,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws -> PolymarketDepositWalletStatus {
        let status: PolymarketDepositWalletStatus

        do {
            status = try await walletService.submitApprovals(signatures.approvals)
        } catch {
            throw PolymarketOnboardingError.wallet(error)
        }

        guard status != .approvalsFailed else {
            throw PolymarketOnboardingError.approvalsFailed
        }

        continuation.yield(.working(status))

        return status
    }

    func finish(
        addresses: Addresses,
        status: PolymarketDepositWalletStatus,
        credentials: PolymarketL2Credentials,
        poller: PolymarketDepositWalletPoller,
        isNewAccount: Bool,
        reporting continuation: PolymarketOnboardingContinuation
    ) async throws {
        if status != .readyToTrade {
            switch try await poller.poll(until: .readyToTrade, from: status, reporting: continuation) {
            case .reached:
                break
            case .ceiling(let reported):
                continuation.yield(.handedOff(reported))
                return
            }
        }

        await primeBalanceCache(credentials: credentials, ownerAddress: addresses.owner)

        continuation.yield(.ready(isNewAccount: isNewAccount))
    }
}

// MARK: - Trading credentials

private extension CommonPolymarketOnboardingInteractor {
    func obtainCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        let credentials: PolymarketL2Credentials

        do {
            credentials = try await clobService.deriveCredentials(authHeaders: authHeaders)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard error.isClientRefusal else {
                PolymarketLogger.error("Failed to derive the trading credentials", error: error)
                throw PolymarketOnboardingError.credentials
            }

            do {
                credentials = try await clobService.createCredentials(authHeaders: authHeaders)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                PolymarketLogger.error("Failed to create the trading credentials", error: error)
                throw PolymarketOnboardingError.credentials
            }
        }

        do {
            try credentialsRepository.save(credentials: credentials, userWalletId: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to store the trading credentials", error: error)
            throw PolymarketOnboardingError.credentials
        }

        return credentials
    }

    func primeBalanceCache(credentials: PolymarketL2Credentials, ownerAddress: String) async {
        do {
            try await clobService.updateBalanceAllowance(credentials: credentials, ownerAddress: ownerAddress)
        } catch {
            PolymarketLogger.error("Failed to prime the collateral balance", error: error)
        }
    }
}

// MARK: - Client refusals

private extension Error {
    var isClientRefusal: Bool {
        guard let apiError = self as? PolymarketAPIError else { return false }

        return apiError.isClientRefusal
    }
}

private extension PolymarketAPIError {
    var isClientRefusal: Bool {
        guard case .http(let statusCode, _) = self else { return false }

        return (400 ..< 500).contains(statusCode)
    }
}

// MARK: - Constants

private extension CommonPolymarketOnboardingInteractor {
    enum Constants {
        static let deadlineOffset = 600
    }
}
