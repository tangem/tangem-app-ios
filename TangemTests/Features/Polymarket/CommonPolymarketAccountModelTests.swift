//
//  CommonPolymarketAccountModelTests.swift
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

        await sut.lookupByWalletId()

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
            .success(PolymarketDepositWalletState(depositWalletAddress: nil, status: .deploymentInProgress)),
            .success(PolymarketDepositWalletState(depositWalletAddress: nil, status: .unknown)),
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
            clobService: PolymarketCLOBServiceStub(balanceResult: .failure(PolymarketAPIError.http(statusCode: 401, problemDetail: nil)))
        )

        await sut.refreshState()

        #expect(credentials.deletedWalletIds.count == 1)
        #expect(sut.state == .syncNeeded)
        #expect(balance.unavailableCalls == 1)
    }

    @Test("A cancelled refresh does not resurrect a state that has since been replaced")
    func cancelledRefreshKeepsTheNewerState() async {
        let service = PolymarketDepositWalletServiceStub(stateResults: [
            .success(PolymarketDepositWalletState(depositWalletAddress: nil, status: .deploymentInProgress)),
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

    @Test("Without a derived key the account is looked up by its Tangem id")
    func underivedKeyLooksUpByWalletId() async {
        let service = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, _) = makeSUT(walletService: service, ownerAddress: nil)

        await sut.lookupByWalletId()

        #expect(service.requestedKeys.map(\.ownerAddress) == [nil])
        #expect(service.requestedKeys.map(\.walletId) == [Self.userWalletId.stringValue])
    }

    @Test("A refresh without a derived key asks nothing and keeps what the lookup found")
    func refreshWithoutDerivedKeyKeepsTheKnownState() async {
        let service = PolymarketDepositWalletServiceStub(status: .readyToTrade)
        let (sut, _) = makeSUT(walletService: service, ownerAddress: nil)

        await sut.lookupByWalletId()
        await sut.refreshState()

        #expect(service.requestedKeys.count == 1)
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

        guard case .success(let value) = balance.updates.last else {
            Issue.record("The balance was never delivered")
            return
        }

        #expect(value == 12.34)
    }
}

// MARK: - Fixtures

private extension CommonPolymarketAccountModelTests {
    static let userWalletId = UserWalletId(value: Data([0x01, 0x02, 0x03]))

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
        ownerAddress: String? = PolymarketOwnerAddressProviderStub.ownerAddress
    ) -> (CommonPolymarketAccountModel, PolymarketBalanceServiceSpy) {
        let balance = PolymarketBalanceServiceSpy()

        let sut = CommonPolymarketAccountModel(
            userWalletId: Self.userWalletId,
            walletService: walletService,
            clobService: clobService,
            credentialsRepository: credentialsRepository,
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: ownerAddress),
            balanceService: balance,
            presenceStore: PolymarketAccountPresenceStoreStub()
        )

        return (sut, balance)
    }
}
