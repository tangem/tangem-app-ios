//
//  CommonPolymarketAccountModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket account state")
struct CommonPolymarketAccountModelTests {
    @Test("A wallet the backend has never seen produces no account at all")
    func notCreatedProducesNoAccount() async {
        let (sut, _) = makeSUT(status: .notCreated)

        await sut.refreshState()

        #expect(sut.state == nil)
    }

    @Test(
        "Every unfinished status maps to the matching onboarding stage",
        arguments: [
            (PolymarketDepositWalletStatus.deploymentInProgress, PolymarketOnboardingStage.deploying),
            (.deployed, .deployed),
            (.approvalsInProgress, .approving),
        ]
    )
    func unfinishedStatusesMapToStages(status: PolymarketDepositWalletStatus, stage: PolymarketOnboardingStage) async {
        let (sut, _) = makeSUT(status: status)

        await sut.refreshState()

        #expect(sut.state == .onboarding(stage))
    }

    @Test("A ready wallet with both a derived key and credentials is active")
    func readyWithKeyAndCredentialsIsActive() async {
        let (sut, _) = makeSUT(status: .readyToTrade, credentials: PolymarketCredentialsRepositoryStub.credentials)

        await sut.refreshState()

        #expect(sut.state == .active)
    }

    @Test("A ready wallet without credentials needs a sync rather than claiming to be active")
    func readyWithoutCredentialsNeedsSync() async {
        let (sut, balance) = makeSUT(status: .readyToTrade)

        await sut.refreshState()

        #expect(sut.state == .syncNeeded)
        #expect(balance.unavailableCalls == 1)
    }

    @Test("Credentials without a derived key cannot read a balance, so the account is not active")
    func readyWithoutDerivedKeyNeedsSync() async {
        let (sut, balance) = makeSUT(
            status: .readyToTrade,
            credentials: PolymarketCredentialsRepositoryStub.credentials,
            ownerAddress: nil
        )

        await sut.refreshState()

        #expect(sut.state == .syncNeeded)
        #expect(balance.unavailableCalls == 1)
    }

    @Test("An unrecognised status does not leave the account spinning forever")
    func unrecognisedStatusDoesNotStickInLoading() async {
        let (sut, _) = makeSUT(status: .unknown)

        await sut.refreshState()

        #expect(sut.state == nil)
    }

    @Test("An unrecognised status keeps whatever was already known")
    func unrecognisedStatusKeepsTheKnownState() async {
        let service = PolymarketDepositWalletServiceStub(stateResults: [
            .success(PolymarketDepositWallet(address: nil, status: .deploymentInProgress)),
            .success(PolymarketDepositWallet(address: nil, status: .unknown)),
        ])
        let (sut, _) = makeSUT(walletService: service)

        await sut.refreshState()
        await sut.refreshState()

        #expect(sut.state == .onboarding(.deploying))
    }

    @Test("A rejected credential is dropped so the next tap can re-authorise")
    func rejectedCredentialsAreDropped() async {
        let credentials = PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials)

        let (sut, balance) = makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: .readyToTrade),
            credentialsRepository: credentials,
            clobService: PolymarketCLOBServiceStub(
                balanceResult: .failure(PolymarketAPIError.http(statusCode: 401, problemDetail: nil))
            )
        )

        await sut.refreshState()

        #expect(credentials.deletedWalletIds.count == 1)
        #expect(sut.state == .syncNeeded)
        #expect(balance.unavailableCalls == 1)
    }

    @Test("A cancelled refresh does not resurrect a state that has since been replaced")
    func cancelledRefreshKeepsTheNewerState() async {
        let service = PolymarketDepositWalletServiceStub(stateResults: [
            .success(PolymarketDepositWallet(address: nil, status: .deploymentInProgress)),
            .failure(.cancelled),
        ])
        let (sut, _) = makeSUT(walletService: service)

        await sut.refreshState()
        await sut.refreshState()

        #expect(sut.state == .onboarding(.deploying))
    }

    @Test("A failed lookup leaves the account unavailable rather than absent")
    func failedLookupIsUnavailable() async {
        let (sut, _) = makeSUT(walletService: PolymarketDepositWalletServiceStub(stateError: .upstreamUnavailable(detail: nil)))

        await sut.refreshState()

        #expect(sut.state == .unavailable)
    }

    @Test("Without a derived key the account is asked for by its Tangem id")
    func underivedKeyAsksByWalletId() async {
        let service = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, _) = makeSUT(walletService: service, ownerAddress: nil)

        await sut.refreshState()

        #expect(service.requestedOwnerAddresses == [nil])
    }

    @Test("A remembered account is served from local facts alone, without asking the backend")
    func aRememberedAccountSkipsTheBackend() async {
        let service = PolymarketDepositWalletServiceStub(status: .notCreated)
        let clob = PolymarketCLOBServiceStub(balanceResult: .success(7.5))

        let (sut, balance) = makeSUT(
            walletService: service,
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            clobService: clob,
            knownAccount: true
        )

        await sut.refreshState()

        #expect(service.requestedOwnerAddresses.isEmpty)
        #expect(sut.state == .active)
        #expect(balance.updates.first?.isLoading == true)

        guard case .loaded(let value) = balance.updates.last else {
            Issue.record("The balance was never delivered")
            return
        }

        #expect(value.available == 7.5)
    }

    @Test("A remembered account without credentials still shows up, only without a balance")
    func aRememberedAccountWithoutCredentialsNeedsSync() async {
        let service = PolymarketDepositWalletServiceStub(status: .notCreated)
        let (sut, balance) = makeSUT(
            walletService: service,
            credentialsRepository: PolymarketCredentialsRepositoryStub(),
            knownAccount: true
        )

        await sut.refreshState()

        #expect(service.requestedOwnerAddresses.isEmpty)
        #expect(sut.state == .syncNeeded)
        #expect(balance.unavailableCalls == 1)
    }

    @Test("The first refresh reports itself as loading")
    func theFirstRefreshPublishesLoading() async {
        let service = PolymarketDepositWalletServiceStub(status: .deploymentInProgress)
        let (sut, _) = makeSUT(walletService: service)

        var states: [PolymarketAccountState?] = []
        let subscription = sut.statePublisher.sink { states.append($0) }

        await sut.refreshState()
        subscription.cancel()

        #expect(states == [nil, .loading, .onboarding(.deploying)])
    }

    @Test("Once the account is known to exist, a refresh stops going to the backend for it")
    func aKnownAccountIsNotAskedForAgain() async {
        let service = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, _) = makeSUT(walletService: service, ownerAddress: nil)

        await sut.refreshState()
        await sut.refreshState()

        #expect(service.requestedOwnerAddresses.count == 1)
        #expect(sut.state == .syncNeeded)
    }

    @Test("An active account is only claimed once the balance has actually been asked for")
    func anActiveAccountReadsItsBalance() async {
        let clob = PolymarketCLOBServiceStub(balanceResult: .success(12.34))
        let (sut, balance) = makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: .readyToTrade),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            clobService: clob
        )

        await sut.refreshState()

        #expect(clob.balanceCalls == 1)

        guard case .loaded(let value) = balance.updates.last else {
            Issue.record("The balance was never delivered")
            return
        }

        #expect(value.available == 12.34)
    }

    @Test("A cancelled balance load does not leave the row loading forever")
    func aCancelledBalanceLoadSettlesTheRow() async {
        let (sut, balance) = makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: .readyToTrade),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            clobService: PolymarketCLOBServiceStub(balanceResult: .failure(CancellationError()))
        )

        await sut.refreshState()

        #expect(balance.updates.first?.isLoading == true)
        #expect(balance.updates.last?.isLoading == false)
        #expect(balance.updates.last?.isUnavailable == true)
    }
}

// MARK: - Positions value

extension CommonPolymarketAccountModelTests {
    @Test("A refresh that joined a round already past its state read starts one of its own")
    func aJoinedRoundThatSkippedTheStateIsFollowedByAnother() async throws {
        let wallet = GatedDepositWalletServiceStub(status: .deploymentInProgress)
        let (sut, _) = makeSUT(walletService: wallet)

        async let first: Void = sut.refreshState()

        await wallet.waitUntilAsked()

        async let second: Void = sut.refreshState()

        await wallet.release()
        _ = await (first, second)

        #expect(wallet.requestedOwnerAddresses.count == 2)
    }

    @Test("A full round reads the positions, and the total holds both parts")
    func fullRoundReadsPositions() async {
        let positions = PolymarketPositionsValueServiceStub(result: .success(7))
        let (sut, balance) = makeActiveSUT(available: 10, positionsValueService: positions)

        await sut.refreshState(scope: .full)

        #expect(positions.calls == 1)
        #expect(balance.lastLoadedBalance?.available == 10)
        #expect(balance.lastLoadedBalance?.total == 17)
    }

    @Test("A round that only wants the available balance keeps the total but leaves the positions request alone")
    func availableOnlyRoundSkipsThePositionsRequest() async {
        let positions = PolymarketPositionsValueServiceStub(result: .success(7))
        let (sut, balance) = makeActiveSUT(available: 10, positionsValueService: positions)

        await sut.refreshState(scope: .full)
        await sut.refreshState(scope: .availableOnly)

        #expect(positions.calls == 1)
        #expect(balance.lastLoadedBalance?.total == 17)
        #expect(balance.lastLoadedBalance?.freshTotal == nil)
    }

    @Test("A refresh that names no scope reads the positions too, because the wallet's main screen shows the total")
    func aPlainRefreshReadsPositions() async {
        let positions = PolymarketPositionsValueServiceStub(result: .success(7))
        let (sut, balance) = makeActiveSUT(available: 10, positionsValueService: positions)

        await sut.refreshState()

        #expect(positions.calls == 1)
        #expect(balance.lastLoadedBalance?.available == 10)
        #expect(balance.lastLoadedBalance?.total == 17)
    }

    @Test("An account with no balance to read is still asked for only once, even though the round wanted the positions")
    func aFullRoundOnAnAccountWithoutABalanceAsksOnce() async {
        let wallet = PolymarketDepositWalletServiceStub(status: .notCreated)
        let (sut, _) = makeSUT(walletService: wallet, credentialsRepository: PolymarketCredentialsRepositoryStub())

        await sut.refreshState(scope: .full)

        #expect(wallet.requestedOwnerAddresses.count == 1)
    }

    @Test("An account that needs a sync settles after a single round as well")
    func aFullRoundOnAnAccountThatNeedsSyncSettlesAtOnce() async {
        let wallet = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, balance) = makeSUT(walletService: wallet, credentialsRepository: PolymarketCredentialsRepositoryStub())

        await sut.refreshState(scope: .full)

        #expect(sut.state == .syncNeeded)
        #expect(balance.unavailableCalls == 1)
    }

    @Test("Skipping the positions before anything is known leaves the total unknown instead of pretending there are no bets")
    func availableOnlyRoundWithoutAnythingKnownLeavesTheTotalUnknown() async {
        let positions = PolymarketPositionsValueServiceStub(result: .success(7))
        let (sut, balance) = makeActiveSUT(available: 10, positionsValueService: positions)

        await sut.refreshState(scope: .availableOnly)

        #expect(positions.calls == 0)
        #expect(balance.lastLoadedBalance?.available == 10)
        #expect(balance.lastLoadedBalance?.total == nil)
    }

    @Test("A failed positions request leaves the available balance untouched")
    func failedPositionsRequestLeavesTheAvailableBalanceAlone() async {
        let positions = PolymarketPositionsValueServiceStub(result: .failure(PolymarketPositionsValueServiceStub.StubError()))
        let (sut, balance) = makeActiveSUT(available: 10, positionsValueService: positions)

        await sut.refreshState(scope: .full)

        #expect(balance.lastLoadedBalance?.available == 10)
        #expect(balance.lastLoadedBalance?.total == nil)
        #expect(balance.updates.contains { $0.isFailed } == false)
    }

    @Test("Positions that failed stop being carried over, so a later skipped round does not resurrect them")
    func failedPositionsAreNotReusedLater() async {
        let positions = PolymarketPositionsValueServiceStub(result: .success(7))
        let (sut, balance) = makeActiveSUT(available: 10, positionsValueService: positions)

        await sut.refreshState(scope: .full)
        positions.result = .failure(PolymarketPositionsValueServiceStub.StubError())
        await sut.refreshState(scope: .full)
        await sut.refreshState(scope: .availableOnly)

        #expect(positions.calls == 2)
        #expect(balance.lastLoadedBalance?.total == nil)
    }
}

// MARK: - Fixtures

private extension CommonPolymarketAccountModelTests {
    static let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))

    func makeActiveSUT(
        available: Decimal,
        positionsValueService: PolymarketPositionsValueService
    ) -> (CommonPolymarketAccountModel, PolymarketBalanceServiceSpy) {
        makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: .readyToTrade),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            clobService: PolymarketCLOBServiceStub(balanceResult: .success(available)),
            positionsValueService: positionsValueService
        )
    }

    @Test("Refreshing the balance never asks the backend for the account's status")
    func balanceRefreshLeavesTheStatusAlone() async {
        let wallet = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, _) = makeSUT(walletService: wallet, credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials))

        await sut.refreshState()
        let afterStateRefresh = wallet.requestedOwnerAddresses.count

        await sut.refreshBalance(scope: .full)

        #expect(wallet.requestedOwnerAddresses.count == afterStateRefresh)
    }

    @Test("An account nobody has read yet is read once, so its balance has a state to load against")
    func balanceRefreshReadsAnUnknownAccountOnce() async {
        let wallet = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, balance) = makeSUT(walletService: wallet, credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials))

        await sut.refreshBalance(scope: .full)

        #expect(wallet.requestedOwnerAddresses.count == 1)
        #expect(sut.state?.isActive == true)
        #expect(balance.unavailableCalls == 0)
    }

    @Test("Reading an active account's balance asks for the launch deposit scan with its owner")
    func balanceRefreshAsksForTheLaunchScan() async {
        let reconciler = PolymarketLaunchDepositsReconcilerStub()
        let (sut, _) = makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: .readyToTrade),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            depositsReconciler: reconciler
        )

        await sut.refreshBalance(scope: .full)

        #expect(reconciler.ownerAddresses == [PolymarketOwnerAddressProviderStub.ownerAddress])
    }

    @Test("An account without credentials reads no balance and asks for no deposit scan")
    func noCredentialsMeansNoLaunchScan() async {
        let reconciler = PolymarketLaunchDepositsReconcilerStub()
        let (sut, _) = makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: .readyToTrade),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: nil),
            depositsReconciler: reconciler
        )

        await sut.refreshBalance(scope: .full)

        #expect(reconciler.ownerAddresses.isEmpty)
    }

    func makeSUT(
        status: PolymarketDepositWalletStatus,
        credentials: PolymarketL2Credentials? = nil,
        ownerAddress: String? = PolymarketOwnerAddressProviderStub.ownerAddress
    ) -> (CommonPolymarketAccountModel, PolymarketBalanceServiceSpy) {
        makeSUT(
            walletService: PolymarketDepositWalletServiceStub(status: status),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: credentials),
            ownerAddress: ownerAddress
        )
    }

    func makeSUT(
        walletService: PolymarketDepositWalletService,
        credentials: PolymarketL2Credentials? = nil,
        ownerAddress: String? = PolymarketOwnerAddressProviderStub.ownerAddress
    ) -> (CommonPolymarketAccountModel, PolymarketBalanceServiceSpy) {
        makeSUT(
            walletService: walletService,
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: credentials),
            ownerAddress: ownerAddress
        )
    }

    func makeSUT(
        walletService: PolymarketDepositWalletService,
        credentialsRepository: PolymarketCredentialsRepository,
        clobService: PolymarketCLOBService = PolymarketCLOBServiceStub(),
        positionsValueService: PolymarketPositionsValueService = PolymarketPositionsValueServiceStub(),
        ownerAddress: String? = PolymarketOwnerAddressProviderStub.ownerAddress,
        knownAccount: Bool = false,
        depositsReconciler: PolymarketLaunchDepositsReconcilerStub = PolymarketLaunchDepositsReconcilerStub()
    ) -> (CommonPolymarketAccountModel, PolymarketBalanceServiceSpy) {
        let balance = PolymarketBalanceServiceSpy()

        let sut = CommonPolymarketAccountModel(
            userWalletId: Self.userWalletId,
            walletService: walletService,
            clobService: clobService,
            positionsValueService: positionsValueService,
            credentialsRepository: credentialsRepository,
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress),
            balanceService: balance,
            presenceStore: PolymarketAccountPresenceStoreStub(known: knownAccount),
            depositsReconciler: depositsReconciler
        )

        return (sut, balance)
    }
}

private extension PolymarketBalanceServiceSpy {
    var lastLoadedBalance: PolymarketBalance? {
        updates
            .reversed()
            .compactMap { state -> PolymarketBalance? in
                guard case .loaded(let balance) = state else {
                    return nil
                }

                return balance
            }
            .first
    }
}

// MARK: - A wallet service that can be held mid-request

private final class GatedDepositWalletServiceStub: PolymarketDepositWalletService, @unchecked Sendable {
    private(set) var requestedOwnerAddresses: [String?] = []

    private let state: PolymarketDepositWallet
    private let asked = AsyncSignal()
    private let gate = AsyncSignal()

    init(status: PolymarketDepositWalletStatus) {
        state = PolymarketDepositWallet(
            address: PolymarketDepositWalletServiceStub.depositWalletAddress,
            status: status
        )
    }

    func waitUntilAsked() async {
        await asked.wait()
    }

    func release() async {
        await gate.signal()
    }

    func depositWalletState(ownerAddress: String?) async throws(PolymarketWalletError) -> PolymarketDepositWallet {
        requestedOwnerAddresses.append(ownerAddress)

        guard requestedOwnerAddresses.count == 1 else {
            return state
        }

        await asked.signal()
        await gate.wait()

        return state
    }

    func deployWallet(
        ownerAddress: String,
        depositWalletAddress: String
    ) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        state.status
    }

    func submitApprovals(_ batch: PolymarketRelayedBatch) async throws(PolymarketWalletError) -> PolymarketDepositWalletStatus {
        state.status
    }
}

private actor AsyncSignal {
    private var isSignalled = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func signal() {
        isSignalled = true
        waiters.forEach { $0.resume() }
        waiters = []
    }

    func wait() async {
        guard !isSignalled else { return }

        await withCheckedContinuation { waiters.append($0) }
    }
}
