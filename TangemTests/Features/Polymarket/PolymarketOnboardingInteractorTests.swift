//
//  PolymarketOnboardingInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket onboarding run")
struct PolymarketOnboardingInteractorTests {
    @Test("An account that needs nothing finishes without asking for a signature")
    func readyAccountFinishesWithoutSigning() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let sut = try makeSUT(
            walletService: makeWalletService(statuses: [.readyToTrade]),
            credentials: PolymarketCredentialsRepositoryStub.credentials,
            signer: signer
        )

        let progress = await sut.collectProgress()

        #expect(progress.last?.isReady == true)
        #expect(signer.signCalls == 0)
    }

    @Test("A blocked region stops the run before the card is asked to sign")
    func blockedRegionRefusesToOnboard() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let service = try makeWalletService(statuses: [.notCreated])
        let sut = try makeSUT(
            walletService: service,
            signer: signer,
            geoblockService: PolymarketGeoblockServiceStub(isBlocked: true)
        )

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isRegionBlocked == true)
        #expect(signer.signCalls == 0)
        #expect(service.submittedBatches.isEmpty)
    }

    @Test("A region that cannot be read stops the run but can be tried again")
    func unreadableRegionStopsTheRun() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let sut = try makeSUT(
            walletService: makeWalletService(statuses: [.notCreated]),
            signer: signer,
            geoblockService: PolymarketGeoblockServiceStub(error: PolymarketAPIError.connection(underlying: URLError(.timedOut)))
        )

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isRegionUnknown == true)
        #expect(progress.last?.failure?.isRetryable == true)
        #expect(signer.signCalls == 0)
    }

    @Test("Re-authorising an account that owes nothing does not consult the region")
    func readyAccountSkipsTheRegionCheck() async throws {
        let sut = try makeSUT(
            walletService: makeWalletService(statuses: [.readyToTrade]),
            credentials: PolymarketCredentialsRepositoryStub.credentials,
            geoblockService: PolymarketGeoblockServiceStub(isBlocked: true)
        )

        let progress = await sut.collectProgress()

        #expect(progress.last?.isReady == true)
    }

    @Test("A refused deployment ends the run rather than being retried behind the user")
    func deployFailureEndsTheRun() async throws {
        let service = try makeWalletService(
            statuses: [.notCreated],
            deployResults: [.success(.deploymentFailed), .success(.deployed)]
        )
        let sut = try makeSUT(walletService: service)

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isDeploymentFailed == true)
        #expect(service.deployCalls == 1)
    }

    @Test("A deployment refused twice is reported instead of polled for two minutes")
    func deployFailureIsReportedImmediately() async throws {
        let service = try makeWalletService(
            statuses: [.notCreated],
            deployResults: [.success(.deploymentFailed), .success(.deploymentFailed)]
        )
        let sut = try makeSUT(walletService: service)

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isDeploymentFailed == true)
        #expect(service.deployCalls == 1)
        #expect(service.submittedBatches.isEmpty)
        #expect(service.requestedOwnerAddresses.count == 1)
    }

    @Test("A wallet id bound to another owner is never worth retrying")
    func takenWalletIdIsNotRetryable() async throws {
        let service = try makeWalletService(statuses: [.notCreated], deployResults: [.failure(.conflict(detail: nil))])
        let sut = try makeSUT(walletService: service)

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isWalletIdTaken == true)
        #expect(progress.last?.failure?.isRetryable == false)
    }

    @Test("Credentials that cannot be stored fail the run instead of passing silently")
    func unstorableCredentialsFailTheRun() async throws {
        struct KeychainFailure: Error {}

        let sut = try makeSUT(
            walletService: makeWalletService(statuses: [.readyToTrade]),
            credentialsRepository: PolymarketCredentialsRepositoryStub(saveError: KeychainFailure())
        )

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isCredentials == true)
    }

    @Test("An unrecognised status never costs the user a card tap")
    func unrecognisedStatusDoesNotAskForTheCard() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let sut = try makeSUT(walletService: makeWalletService(statuses: [.unknown]), signer: signer)

        let progress = await sut.collectProgress()

        #expect(progress.last?.isHandedOff == true)
        #expect(signer.signCalls == 0)
    }

    @Test("A backend that never finishes leaves the run still working, not failed")
    func pollingCeilingIsNotAFailure() async throws {
        let sut = try makeSUT(
            walletService: makeWalletService(statuses: [.deployed, .approvalsInProgress]),
            credentials: PolymarketCredentialsRepositoryStub.credentials
        )

        let progress = await sut.collectProgress()

        #expect(progress.last?.isHandedOff == true)
        #expect(progress.last?.failure == nil)
    }

    @Test("A fresh wallet is deployed, authorised and approved in a single card session")
    func freshWalletRunsEndToEnd() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let service = try makeWalletService(statuses: [.notCreated, .deployed, .readyToTrade])
        let sut = try makeSUT(walletService: service, signer: signer)

        let progress = await sut.collectProgress()

        #expect(progress.last?.isReady == true)
        #expect(signer.signCalls == 1)
        #expect(service.deployCalls == 1)
        #expect(service.submittedBatches.count == 1)
    }

    @Test("The batch that reaches the backend is byte for byte the one the card signed")
    func theSubmittedBatchIsTheSignedOne() async throws {
        let deposit = try Self.depositWalletAddress()
        let service = try makeWalletService(statuses: [.deployed, .readyToTrade])
        let sut = try makeSUT(walletService: service)

        _ = await sut.collectProgress()

        let submitted = try #require(service.submittedBatches.first)

        #expect(submitted.ownerAddress == PolymarketOwnerAddressProviderStub.ownerAddress)
        #expect(submitted.depositWalletAddress == deposit)
        #expect(submitted.nonce == PolymarketRelayerServiceStub.nonce)
        #expect(submitted.signature == PolymarketOnboardingSignerSpy.batchSignature)
        #expect(submitted.calls == PolymarketApprovalCalls.make())
    }

    @Test("The approvals deadline is measured by the backend's clock, not by a device running half an hour behind")
    func deadlineFollowsTheBackendClock() async throws {
        let skew: TimeInterval = 1800
        let serverClock = PolymarketServerClock()
        serverClock.record(serverDate: Date().addingTimeInterval(skew))

        let service = try makeWalletService(statuses: [.deployed, .readyToTrade])
        let sut = try makeSUT(walletService: service, serverClock: serverClock)

        let before = Date().timeIntervalSince1970
        _ = await sut.collectProgress()

        let submitted = try #require(service.submittedBatches.first)
        let deadline = try #require(TimeInterval(submitted.deadline))

        #expect(abs(deadline - (before + skew + 600)) <= 10)
    }

    @Test("A conflict on approvals is worth retrying, unlike the same code on deploy")
    func conflictOnApprovalsIsRetryable() async throws {
        let service = try makeWalletService(statuses: [.deployed], approvalsResult: .failure(.conflict(detail: nil)))
        let sut = try makeSUT(walletService: service)

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isWallet == true)
        #expect(progress.last?.failure?.isRetryable == true)
    }

    @Test("A handful of network blips while polling does not end the run")
    func transientPollingFailuresAreTolerated() async throws {
        let deposit = try Self.depositWalletAddress()
        let service = PolymarketDepositWalletServiceStub(stateResults: [
            .success(PolymarketDepositWallet(address: deposit, status: .approvalsInProgress)),
            .failure(.other(.connection(underlying: PolymarketDepositWalletServiceStub.StubError()))),
            .success(PolymarketDepositWallet(address: deposit, status: .readyToTrade)),
        ])
        let sut = try makeSUT(walletService: service, credentials: PolymarketCredentialsRepositoryStub.credentials)

        let progress = await sut.collectProgress()

        #expect(progress.last?.isReady == true)
    }

    @Test("A deposit wallet the backend disagrees about stops the run before any signature")
    func mismatchedDepositWalletStopsTheRun() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let service = PolymarketDepositWalletServiceStub(
            status: .deployed,
            depositWalletAddress: "0xdef0000000000000000000000000000000000009"
        )
        let sut = try makeSUT(walletService: service, signer: signer)

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isAddressMismatch == true)
        #expect(signer.signCalls == 0)
    }

    @Test("A deposit wallet the backend only reveals while polling still stops the run")
    func mismatchedDepositWalletFoundWhilePollingStopsTheRun() async throws {
        let signer = PolymarketOnboardingSignerSpy()
        let service = PolymarketDepositWalletServiceStub(stateResults: [
            .success(PolymarketDepositWallet(address: nil, status: .unknown)),
            .success(PolymarketDepositWallet(address: "0xdef0000000000000000000000000000000000009", status: .deployed)),
        ])
        let sut = try makeSUT(walletService: service, signer: signer)

        let progress = await sut.collectProgress()

        #expect(progress.last?.failure?.isAddressMismatch == true)
        #expect(signer.signCalls == 0)
    }

    @Test("Cancelling while the trading credentials are created ends the run quietly")
    func cancellationWhileCreatingCredentialsIsNotAFailure() async throws {
        let sut = try makeSUT(
            walletService: makeWalletService(statuses: [.readyToTrade]),
            clobService: PolymarketCLOBServiceStub(
                deriveResult: .failure(PolymarketAPIError.http(statusCode: 404, problemDetail: nil)),
                createResult: .failure(CancellationError())
            )
        )

        let progress = await sut.collectProgress()

        #expect(progress.allSatisfy { $0.failure == nil })
    }

    @Test("The first polled status reaches the screen even when nothing changed yet")
    func theFirstPolledStatusIsReported() async throws {
        let deposit = try Self.depositWalletAddress()
        let service = PolymarketDepositWalletServiceStub(stateResults: [
            .success(PolymarketDepositWallet(address: deposit, status: .deploymentInProgress)),
            .success(PolymarketDepositWallet(address: deposit, status: .deploymentInProgress)),
            .success(PolymarketDepositWallet(address: deposit, status: .readyToTrade)),
        ])
        let sut = try makeSUT(walletService: service, credentials: PolymarketCredentialsRepositoryStub.credentials)

        let progress = await sut.collectProgress()
        let firstWorkingIndex = try #require(progress.firstIndex { $0.isWorking })
        let awaitingSignatureIndex = try #require(progress.firstIndex { $0.isAwaitingSignature })

        #expect(firstWorkingIndex > awaitingSignatureIndex)
        #expect(progress.last?.isReady == true)
    }

    @Test("A run the user walked away from ends quietly instead of reporting a failure")
    func cancellationIsNeverReportedAsFailure() async throws {
        let service = PolymarketDepositWalletServiceStub(stateResults: [.failure(.cancelled)])
        let sut = try makeSUT(walletService: service)

        let progress = await sut.collectProgress()

        #expect(progress.allSatisfy { $0.failure == nil })
    }
}

// MARK: - Fixtures

private extension PolymarketOnboardingInteractorTests {
    static let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))

    static func depositWalletAddress() throws -> String {
        try PolymarketDepositWalletDeriver.derive(ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress)
    }

    func makeWalletService(
        statuses: [PolymarketDepositWalletStatus],
        deployResults: [Result<PolymarketDepositWalletStatus, PolymarketWalletError>] = [.success(.deploymentInProgress)],
        approvalsResult: Result<PolymarketDepositWalletStatus, PolymarketWalletError> = .success(.approvalsInProgress)
    ) throws -> PolymarketDepositWalletServiceStub {
        let deposit = try Self.depositWalletAddress()

        return PolymarketDepositWalletServiceStub(
            stateResults: statuses.map { status in
                let address = status == .notCreated ? nil : deposit

                return .success(PolymarketDepositWallet(address: address, status: status))
            },
            deployResults: deployResults,
            approvalsResult: approvalsResult
        )
    }

    func makeSUT(
        walletService: PolymarketDepositWalletService,
        credentials: PolymarketL2Credentials? = nil,
        credentialsRepository: PolymarketCredentialsRepository? = nil,
        signer: PolymarketOnboardingSigning = PolymarketOnboardingSignerSpy(),
        geoblockService: PolymarketGeoblockService = PolymarketGeoblockServiceStub(),
        clobService: PolymarketCLOBService = PolymarketCLOBServiceStub(),
        serverClock: PolymarketServerClock = PolymarketServerClock()
    ) throws -> CommonPolymarketOnboardingInteractor {
        CommonPolymarketOnboardingInteractor(
            userWalletId: Self.userWalletId,
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            signer: signer,
            credentialsRepository: credentialsRepository ?? PolymarketCredentialsRepositoryStub(stored: credentials),
            geoblockService: geoblockService,
            walletService: walletService,
            relayerService: PolymarketRelayerServiceStub(),
            clobService: clobService,
            serverClock: serverClock,
            pollInterval: 0
        )
    }
}

// MARK: - Progress helpers

private extension PolymarketOnboardingInteractor {
    func collectProgress() async -> [PolymarketOnboardingProgress] {
        var collected: [PolymarketOnboardingProgress] = []

        for await progress in onboard() {
            collected.append(progress)
        }

        return collected
    }
}

private extension PolymarketOnboardingProgress {
    var failure: PolymarketOnboardingError? {
        guard case .failed(let error) = self else { return nil }

        return error
    }
}
