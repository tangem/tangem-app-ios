//
//  YieldIncentivesClaimInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import Testing
@testable import Tangem

@Suite("YieldIncentivesClaimInteractor", .serialized, .timeLimit(.minutes(1)))
struct YieldIncentivesClaimInteractorTests {
    private typealias Fixtures = YieldIncentivesFixtures
    private typealias ClaimError = YieldIncentivesClaimInteractor.ClaimError

    @Test("A preparation carries the validated destination, payload and fee")
    func preparationCarriesTheValidatedPayload() async throws {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            let prepared = try await sut.prepare()

            #expect(prepared.to == Fixtures.moduleAddress)
            #expect(prepared.data == Data(hexString: Fixtures.calldataHex))
            #expect(prepared.fee.totalFeeAmount.value == Decimal(string: "0.001")!)
            #expect(network.calldataCallCount == 1)
            #expect(manager.feeCalls == [.init(to: prepared.to, dataHex: prepared.data.hexString)])
        }
    }

    @Test("A module answering for another chain is refused before any request")
    func foreignChainIsRefused() async {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub()
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(chainId: 1, manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .moduleUnavailable) }

            #expect(network.calldataCallCount == 0)
            #expect(incentives.incentivesCallCount == 0)
        }
    }

    @Test("A calldata the validator refuses never reaches the fee estimate")
    func refusedCalldataNeverReachesTheFeeEstimate() async {
        let network = YieldClaimNetworkManagerStub()
        network.setCalldataResult(.success(Fixtures.calldata(claimRecommended: false)))
        let manager = YieldClaimManagerStub()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .validationFailed(.notRecommended)) }

            #expect(manager.feeCalls.isEmpty)
        }
    }

    @Test("Rewards that vanished between the banner and the sheet stop the preparation")
    func vanishedRewardsStopThePreparation() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub(incentivesManager: YieldClaimIncentivesManagerStub(summary: nil))

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .rewardsUnavailable) }
        }
    }

    @Test("A wallet refresh does not lose the module address the claim is validated against")
    func walletRefreshKeepsTheModuleAddress() async throws {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub(state: Fixtures.refreshingState())

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            let prepared = try await sut.prepare()

            #expect(prepared.to == Fixtures.moduleAddress)
        }
    }

    @Test("Rewards reported for another module are refused")
    func rewardsFromAnotherModuleAreRefused() async {
        let network = YieldClaimNetworkManagerStub()
        let foreignSummary = Fixtures.summary(moduleAddress: "0x0000000000000000000000000000000000000004")
        let manager = YieldClaimManagerStub(incentivesManager: YieldClaimIncentivesManagerStub(summary: foreignSummary))

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .rewardsUnavailable) }
        }
    }

    @Test("Rewards that are only pending leave nothing to prepare")
    func pendingOnlyRewardsStopThePreparation() async {
        let network = YieldClaimNetworkManagerStub()
        let pendingOnly = Fixtures.summary(rewards: [Fixtures.reward(claimableAmount: 0)])
        let manager = YieldClaimManagerStub(incentivesManager: YieldClaimIncentivesManagerStub(summary: pendingOnly))

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .rewardsUnavailable) }
        }
    }

    @Test("Calldata claiming a token whose destination is unsupported is refused")
    func calldataForAnUnsupportedRewardIsRefused() async {
        let unsupportedToken = "0x0000000000000000000000000000000000000005"
        let network = YieldClaimNetworkManagerStub()
        network.setCalldataResult(
            .success(
                Fixtures.calldata(
                    rewardTokens: [Fixtures.rewardToken, unsupportedToken],
                    cumulativeAmounts: ["1", "2"]
                )
            )
        )

        let summary = Fixtures.summary(
            rewards: [
                Fixtures.reward(),
                Fixtures.reward(rewardTokenAddress: unsupportedToken, destination: .unsupported),
            ]
        )
        let manager = YieldClaimManagerStub(incentivesManager: YieldClaimIncentivesManagerStub(summary: summary))

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .validationFailed(.unsupportedRewardToken)) }
        }
    }

    @Test("A module without the incentives feature has nothing to prepare")
    func missingIncentivesManagerIsRefused() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub(incentivesManager: nil)

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .moduleUnavailable) }
        }
    }

    @Test("The rewards behind a claim are always refetched rather than served from the cache")
    func theSummaryBehindAClaimIsAlwaysRefetched() async throws {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub()
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            _ = try await sut.prepare()

            #expect(incentives.forceRefreshFlags == [true])
        }
    }

    @Test("A cancelled rewards fetch is reported as cancellation, not as missing rewards")
    func cancelledSummaryFetchIsRethrown() async {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub(summary: nil, error: CancellationError())
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { $0 is CancellationError }
        }
    }

    @Test("A failed rewards fetch is reported as missing rewards")
    func failedSummaryFetchBecomesRewardsUnavailable() async {
        let network = YieldClaimNetworkManagerStub()
        let incentives = YieldClaimIncentivesManagerStub(summary: nil, error: YieldIncentivesTestError.network)
        let manager = YieldClaimManagerStub(incentivesManager: incentives)

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager)

            await #expect {
                _ = try await sut.prepare()
            } throws: { isSameCase($0, as: .rewardsUnavailable) }
        }
    }

    @Test("A preparation older than its validity window is refused without touching the guard")
    func expiredPreparationIsRefused() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        let tracker = YieldIncentivesClaimTracker()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)
            let prepared = Fixtures.preparedClaim(preparedAt: Date(timeIntervalSinceNow: -121))

            await #expect {
                _ = try await sut.claim(prepared: prepared, isFeeCovered: { _ in true })
            } throws: { isSameCase($0, as: .preparationExpired) }

            #expect(await !tracker.isClaimInFlight)
            #expect(manager.builtCalls.isEmpty)
        }
    }

    @Test("The fee is checked before the transaction is built")
    func feeIsCheckedBeforeTheTransactionIsBuilt() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        let tracker = YieldIncentivesClaimTracker()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)

            await #expect {
                _ = try await sut.claim(prepared: Fixtures.preparedClaim(), isFeeCovered: { _ in false })
            } throws: { isSameCase($0, as: .insufficientFee) }

            #expect(manager.builtCalls.isEmpty)
            #expect(manager.submittedTransactions.isEmpty)
            #expect(await !tracker.isClaimInFlight)
        }
    }

    @Test("A transaction signed from another address is never submitted")
    func foreignSourceAddressIsNeverSubmitted() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        manager.setTransactionResult(.success(Fixtures.transaction(sourceAddress: "0x0000000000000000000000000000000000000009")))
        let tracker = YieldIncentivesClaimTracker()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)

            await #expect {
                _ = try await sut.claim(prepared: Fixtures.preparedClaim(), isFeeCovered: { _ in true })
            } throws: { isSameCase($0, as: .moduleUnavailable) }

            #expect(manager.submittedTransactions.isEmpty)
            #expect(await !tracker.isClaimInFlight)
        }
    }

    @Test("The submitted transaction is built from the payload the sheet showed")
    func submittedTransactionMatchesThePreparedPayload() async throws {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        let tracker = YieldIncentivesClaimTracker()
        let recorder = ClaimEventRecorder(tracker: tracker)

        try await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)
            let prepared = Fixtures.preparedClaim()

            let submitted = try await sut.claim(prepared: prepared, isFeeCovered: { _ in true })

            #expect(submitted.transactionHash == "0xclaimhash")
            #expect(manager.builtCalls == [.init(to: prepared.to, dataHex: prepared.data.hexString)])
            #expect(manager.submittedTransactions.count == 1)

            await recorder.waitForSettlement()

            #expect(manager.pendingWatchedHashes == ["0xclaimhash"])
            #expect(recorder.events == [.submitted, .settled])
        }
    }

    @Test("A claim already in flight is refused before anything is signed")
    func claimInFlightIsRefused() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        let tracker = YieldIncentivesClaimTracker()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)
            _ = await tracker.beginClaim()

            await #expect {
                _ = try await sut.claim(prepared: Fixtures.preparedClaim(), isFeeCovered: { _ in true })
            } throws: { isSameCase($0, as: .claimAlreadyInFlight) }

            #expect(manager.builtCalls.isEmpty)
        }
    }

    @Test("A declined signature frees the guard for the next attempt")
    func declinedSignatureFreesTheGuard() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        manager.setSubmitResult(.failure(CancellationError()))
        let tracker = YieldIncentivesClaimTracker()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)

            await #expect {
                _ = try await sut.claim(prepared: Fixtures.preparedClaim(), isFeeCovered: { _ in true })
            } throws: { $0 is CancellationError }

            #expect(await !tracker.isClaimInFlight)
        }
    }

    @Test("An unresolved submission keeps the guard until the tracker settles it")
    func unresolvedSubmissionKeepsTheGuard() async {
        let network = YieldClaimNetworkManagerStub()
        let manager = YieldClaimManagerStub()
        manager.setSubmitResult(.failure(YieldIncentivesTestError.network))
        let tracker = YieldIncentivesClaimTracker()

        await withInjectedYieldNetworkManager(network) {
            let sut = makeSUT(manager: manager, tracker: tracker)

            await #expect {
                _ = try await sut.claim(prepared: Fixtures.preparedClaim(), isFeeCovered: { _ in true })
            } throws: { isSameCase($0, as: .submissionUnresolved) }

            #expect(await tracker.isClaimInFlight)
        }
    }

    private func makeSUT(
        chainId: Int = YieldIncentivesFixtures.chainId,
        userAddress: String = YieldIncentivesFixtures.userAddress,
        manager: YieldModuleManager = YieldClaimManagerStub(),
        tracker: YieldIncentivesClaimTracker = YieldIncentivesClaimTracker()
    ) -> YieldIncentivesClaimInteractor {
        YieldIncentivesClaimInteractor(
            chainId: chainId,
            userAddress: userAddress,
            manager: manager,
            transactionDispatcher: YieldClaimDispatcherStub(),
            tracker: tracker
        )
    }
}

private func isSameCase(_ error: Error, as expected: YieldIncentivesClaimInteractor.ClaimError) -> Bool {
    guard let error = error as? YieldIncentivesClaimInteractor.ClaimError else {
        return false
    }

    switch (error, expected) {
    case (.validationFailed(let lhs), .validationFailed(let rhs)):
        return lhs == rhs
    case (.claimAlreadyInFlight, .claimAlreadyInFlight),
         (.rewardsUnavailable, .rewardsUnavailable),
         (.moduleUnavailable, .moduleUnavailable),
         (.insufficientFee, .insufficientFee),
         (.preparationExpired, .preparationExpired),
         (.submissionUnresolved, .submissionUnresolved):
        return true
    default:
        return false
    }
}
