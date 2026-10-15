//
//  PolymarketWithdrawTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BigInt
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemPolymarket
import TangemSdk
@testable import Tangem

// MARK: - The bytes the card signs

@Suite("Polymarket withdraw calldata")
struct PolymarketWithdrawCallTests {
    @Test("A transfer is packed exactly as the bridge documents it")
    func packsTheDocumentedTransfer() throws {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: 12_500_000)

        #expect(call.target == PolymarketCollateral.contractAddress)
        #expect(call.value == "0")
        #expect(call.data.lowercased() == "0xa9059cbb"
            + "000000000000000000000000" + bridgeAddress.removeHexPrefix().lowercased()
            + String(repeating: "0", count: 58) + "bebc20")
    }

    @Test("The packed bytes read back as the transfer they were built from")
    func readsBackWhatItPacked() throws {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: 12_500_000)
        let decoded = try #require(PolymarketWithdrawCall.decode(call))

        #expect(decoded.amountBaseUnits == 12_500_000)
        #expect(try decoded.recipient == SmartContractAddress(bridgeAddress.lowercased()))
    }

    @Test("The bridge answers in EIP-55, and its own answer must pass the self-check")
    func acceptsTheChecksummedAddressTheBridgeReturns() throws {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: 12_500_000)

        #expect(PolymarketWithdrawCall.carries(call, transferOf: 12_500_000, to: bridgeAddress))
        #expect(PolymarketWithdrawCall.carries(call, transferOf: 12_500_000, to: bridgeAddress.lowercased()))
    }

    @Test("A transfer of another amount is not the transfer that was meant")
    func rejectsAnotherAmount() throws {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: 12_500_000)

        #expect(!PolymarketWithdrawCall.carries(call, transferOf: 12_500_001, to: bridgeAddress))
    }

    @Test("A transfer to another address is not the transfer that was meant")
    func rejectsAnotherRecipient() throws {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: 12_500_000)

        #expect(!PolymarketWithdrawCall.carries(call, transferOf: 12_500_000, to: otherAddress))
    }

    @Test("A call on another contract is not a pUSD transfer, whatever its bytes say")
    func rejectsAnotherTarget() throws {
        let call = try PolymarketWithdrawCall.transfer(to: bridgeAddress, amountBaseUnits: 12_500_000)
        let foreign = PolymarketRelayedBatch.Call(target: otherAddress, data: call.data)

        #expect(PolymarketWithdrawCall.decode(foreign) == nil)
    }
}

// MARK: - The withdrawal itself

@Suite("Polymarket withdrawal")
struct PolymarketWithdrawTransactionServiceTests {
    @Test("The signed batch carries one pUSD transfer of the entered amount to the bridge address")
    func submitsTheTransferTheUserAskedFor() async throws {
        let context = try Context()

        _ = try await context.sut.withdraw(amount: 12.5, to: recipientAddress)

        let batch = try #require(context.withdrawService.submitted.singleElement)
        let call = try #require(batch.calls.singleElement)

        #expect(batch.depositWalletAddress == context.depositWalletAddress)
        #expect(batch.ownerAddress == context.ownerAddress)
        #expect(batch.nonce == PolymarketRelayerServiceStub.nonce)
        #expect(call.target == PolymarketCollateral.contractAddress)
        #expect(PolymarketWithdrawCall.carries(call, transferOf: 12_500_000, to: bridgeAddress))
    }

    @Test("The deadline is ten minutes out, well inside the twenty the backend accepts")
    func deadlineIsInTheNearFuture() async throws {
        let context = try Context()

        let before = Date().timeIntervalSince1970
        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
        let after = Date().timeIntervalSince1970

        let batch = try #require(context.withdrawService.submitted.singleElement)
        let deadline = try #require(TimeInterval(batch.deadline))

        #expect(deadline >= before.rounded(.down) + 600)
        #expect(deadline <= after + 600)
    }

    @Test("The deadline is measured by the backend's clock, not by a device running half an hour behind")
    func deadlineFollowsTheBackendClock() async throws {
        let skew: TimeInterval = 1800
        let serverClock = PolymarketServerClock()
        serverClock.record(serverDate: Date().addingTimeInterval(skew))

        let context = try Context(serverClock: serverClock)

        let before = Date().timeIntervalSince1970
        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        let batch = try #require(context.withdrawService.submitted.singleElement)
        let deadline = try #require(TimeInterval(batch.deadline))

        #expect(abs(deadline - (before + skew + 600)) <= 10)
    }

    @Test("A fraction below the token's precision is dropped, never rounded up past the balance")
    func roundsTheAmountDown() async throws {
        let context = try Context()

        _ = try await context.sut.withdraw(amount: Decimal(string: "1.23456789")!, to: recipientAddress)

        let call = try #require(context.withdrawService.submitted.singleElement?.calls.singleElement)
        let decoded = try #require(PolymarketWithdrawCall.decode(call))

        #expect(decoded.amountBaseUnits == 1_234_567)
    }

    @Test("The destination is the asset the bridge lists, not a constant compiled in")
    func takesTheDestinationFromTheBridgeListing() async throws {
        let context = try Context(assets: [])

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A withdrawal without a listed destination must not be signed")
        } catch PolymarketWithdrawTransactionService.Error.destinationAssetUnavailable {
            #expect(context.withdrawService.submitted.isEmpty)
        }
    }

    @Test("The envelope carries the owner address the deposit wallet was resolved for")
    func carriesTheResolvedOwnerAddress() async throws {
        let context = try Context(ownerAddress: foreignOwnerAddress)

        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        let batch = try #require(context.withdrawService.submitted.singleElement)

        #expect(batch.ownerAddress == foreignOwnerAddress)
    }

    @Test("A submission that never answered is resent as the very same batch")
    func resendsTheSameBatchAfterAnUnfinishedSubmission() async throws {
        let context = try Context(submitResults: [.failure(.other(.connection(underlying: StubError()))), nil])

        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        #expect(context.withdrawService.submitted.count == 2)
        #expect(context.withdrawService.submitted.first == context.withdrawService.submitted.last)
    }

    @Test("An answer that arrived unreadable is not resent")
    func doesNotResendAnUnreadableAnswer() async throws {
        let context = try Context(submitResults: [.failure(.other(.decoding(field: "record", value: "{}")))])

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("An answered submission must not be reported as a success")
        } catch PolymarketWithdrawTransactionService.Error.refused(.other(.decoding)) {
            #expect(context.withdrawService.submitted.count == 1)
        }
    }

    @Test("A refused nonce is a different withdrawal, so it is never resent")
    func doesNotResendARefusedNonce() async throws {
        let context = try Context(submitResults: [.failure(.conflict(detail: nil))])

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A refused submission must not be reported as a success")
        } catch PolymarketWithdrawTransactionService.Error.refused(.conflict) {
            #expect(context.withdrawService.submitted.count == 1)
        }
    }

    @Test("A conflict from a wallet that is no longer ready to trade asks for a reconnect instead of a generic refusal")
    func conflictFromANotReadyWalletRequiresAReconnect() async throws {
        let sessionHealth = PolymarketSessionHealthSpy(verdict: .reconnectRequired)
        let context = try Context(submitResults: [.failure(.conflict(detail: nil))], sessionHealth: sessionHealth)

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A refused submission must not be reported as a success")
        } catch PolymarketWithdrawTransactionService.Error.reconnectRequired {
            #expect(sessionHealth.verifyCalls == 1)
            #expect(context.withdrawService.submitted.count == 1)
            #expect(context.tracker.tracked.isEmpty)
        }
    }

    @Test("A conflict while the wallet is still ready to trade stays the refusal the backend sent")
    func conflictFromAReadyWalletStaysARefusal() async throws {
        let sessionHealth = PolymarketSessionHealthSpy(verdict: .ready)
        let context = try Context(submitResults: [.failure(.conflict(detail: "busy"))], sessionHealth: sessionHealth)

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A refused submission must not be reported as a success")
        } catch PolymarketWithdrawTransactionService.Error.refused(.conflict(let detail)) {
            #expect(detail == "busy")
            #expect(sessionHealth.verifyCalls == 1)
        }
    }

    @Test("A wallet found not ready before signing reports its status and asks for a reconnect, with nothing signed")
    func notReadyWalletRequiresAReconnectBeforeSigning() async throws {
        let sessionHealth = PolymarketSessionHealthSpy(verdict: .reconnectRequired)
        let context = try Context(walletStatus: .deployed, sessionHealth: sessionHealth)

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A wallet that is not ready must not withdraw")
        } catch PolymarketWithdrawTransactionService.Error.reconnectRequired {
            #expect(sessionHealth.reportedStatuses == [.deployed])
            #expect(context.withdrawService.submitted.isEmpty)
        }
    }

    @Test("A wallet status this build does not recognise fails the preparation instead of asking for a reconnect")
    func unrecognisedWalletStatusFailsThePreparation() async throws {
        let sessionHealth = PolymarketSessionHealthSpy(verdict: .inconclusive)
        let context = try Context(walletStatus: .unknown, sessionHealth: sessionHealth)

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A wallet that is not ready must not withdraw")
        } catch PolymarketWithdrawTransactionService.Error.preparationFailed {
            #expect(context.withdrawService.submitted.isEmpty)
        }
    }

    @Test("The address the user is withdrawing to is the address the bridge is told to deliver to")
    func asksTheBridgeToDeliverToTheUsersAddress() async throws {
        let context = try Context()

        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        let route = try #require(context.bridge.requestedRoutes.singleElement)

        #expect(route.recipientAddress == recipientAddress)
        #expect(route.destinationChainId == PolymarketSupportedAsset.usdcOnPolygon.chainId)
        #expect(route.destinationTokenAddress == PolymarketSupportedAsset.usdcOnPolygon.token.address)
    }

    @Test("The builder code reaches the bridge, so the withdrawal is attributed to us")
    func attributesTheWithdrawalToTheBuilderCode() async throws {
        let context = try Context()

        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        #expect(context.bridge.receivedBuilderCodes == [ConfigurationServiceStub.code])
    }

    @Test("A first leg confirmed on submission is reported as confirmed")
    func reportsAConfirmedFirstLeg() async throws {
        let confirmed = PolymarketWithdrawRecord(transactionId: transactionId, state: .confirmed, transactionHash: "0x7ae1")
        let context = try Context(submitResults: [.success(confirmed)])

        let record = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        #expect(record.state == .confirmed)
        #expect(record.transactionHash == "0x7ae1")
    }

    @Test("A first leg still in flight is handed back as it is, without waiting for it to settle")
    func handsBackAnUnsettledFirstLegWithoutWaiting() async throws {
        let accepted = PolymarketWithdrawRecord(transactionId: transactionId, state: .inProgress, transactionHash: nil)
        let context = try Context(submitResults: [.success(accepted)])

        let record = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        #expect(record.state == .inProgress)
        #expect(context.withdrawService.recordRequests == 0)
    }

    @Test("Every submitted withdrawal is handed to the tracker before the send flow learns of it")
    func handsTheSubmittedWithdrawalToTheTracker() async throws {
        let accepted = PolymarketWithdrawRecord(transactionId: transactionId, state: .inProgress, transactionHash: nil)
        let context = try Context(submitResults: [.success(accepted)])

        _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)

        let batch = try #require(context.withdrawService.submitted.singleElement)

        #expect(context.tracker.tracked.map(\.record) == [accepted])
        #expect(context.tracker.tracked.map(\.deadline) == [Date(timeIntervalSince1970: try #require(TimeInterval(batch.deadline)))])
    }

    @Test("A withdrawal the backend refused on submission is never tracked, since it never started")
    func doesNotTrackARefusedSubmission() async throws {
        let context = try Context(submitResults: [.failure(.conflict(detail: nil))])

        _ = try? await context.sut.withdraw(amount: 1, to: recipientAddress)

        #expect(context.tracker.tracked.isEmpty)
    }

    @Test("A failed transfer is reported, since it never executed and may be signed again")
    func reportsAFailedTransfer() async throws {
        let failed = PolymarketWithdrawRecord(transactionId: transactionId, state: .failed, transactionHash: nil)
        let context = try Context(submitResults: [.success(failed)])

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A failed transfer must not be reported as a success")
        } catch PolymarketWithdrawTransactionService.Error.transferFailed(let record) {
            #expect(record.state == .failed)
        }

        #expect(context.tracker.tracked.map(\.record) == [failed])
    }

    @Test("A cancelled card tap leaves the flow as a cancellation")
    func reportsACancelledCardTapAsCancellation() async throws {
        let context = try Context(signing: CancellingSignerStub())

        await #expect(throws: CancellationError.self) {
            try await context.sut.withdraw(amount: 1, to: recipientAddress)
        }

        #expect(context.withdrawService.submitted.isEmpty)
    }

    @Test("An amount below the token's precision is refused before anything is signed")
    func refusesAnAmountBelowTheTokensPrecision() async throws {
        let context = try Context()
        let dust = try #require(Decimal(string: "0.0000001"))

        do {
            _ = try await context.sut.withdraw(amount: dust, to: recipientAddress)
            Issue.record("An amount that rounds to zero must not be signed")
        } catch PolymarketWithdrawTransactionService.Error.amountNotRepresentable {
            #expect(context.withdrawService.submitted.isEmpty)
        }
    }

    @Test("A bridge answer without an EVM address stops the withdrawal instead of signing a transfer to nowhere")
    func refusesAWithdrawalWithoutABridgeAddress() async throws {
        let context = try Context(withdrawAddresses: PolymarketBridgeAddresses(addresses: [:]))

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A withdrawal without a bridge address must not be signed")
        } catch PolymarketWithdrawTransactionService.Error.bridgeAddressUnavailable {
            #expect(context.withdrawService.submitted.isEmpty)
        }
    }

    @Test("A withdrawal started while another is in flight is refused rather than signed alongside it")
    func refusesASecondWithdrawalWhileOneIsInFlight() async throws {
        let configurationService = ReentrantConfigurationServiceStub()
        let context = try Context(configurationService: configurationService)
        let sut = context.sut
        let secondAttempt = OSAllocatedUnfairLock(initialState: SecondAttempt())

        configurationService.setOnFirstCall {
            do {
                _ = try await sut.withdraw(amount: 1, to: recipientAddress)
                secondAttempt.withLock { $0.unexpected = "the second withdrawal succeeded" }
            } catch PolymarketWithdrawTransactionService.Error.withdrawInProgress {
                secondAttempt.withLock { $0.isRefusedAsInProgress = true }
            } catch {
                secondAttempt.withLock { $0.unexpected = String(describing: error) }
            }
        }

        _ = try await sut.withdraw(amount: 1, to: recipientAddress)

        let outcome = secondAttempt.withLock { $0 }

        #expect(outcome.unexpected == nil)
        #expect(outcome.isRefusedAsInProgress)
        #expect(context.withdrawService.submitted.count == 1)
    }

    @Test("A failure with no description of its own still arrives as a readable error")
    func mapsAnUnrecognisedFailureToAReadableError() async throws {
        let context = try Context(configurationService: FailingConfigurationServiceStub())

        do {
            _ = try await context.sut.withdraw(amount: 1, to: recipientAddress)
            Issue.record("A withdrawal that could not be prepared must not be signed")
        } catch PolymarketWithdrawTransactionService.Error.preparationFailed {
            #expect(context.withdrawService.submitted.isEmpty)
        }
    }
}

// MARK: - What the withdrawal offers to choose from

@Suite("Polymarket withdraw pair")
struct PolymarketWithdrawSwapParametersTests {
    @Test("The source is pinned to the prediction account: nothing to pick, nothing to add from markets")
    func sourceIsPinnedToThePredictionAccount() throws {
        let configuration = try makeConfiguration()

        guard case .fixed = configuration.sourceTokenSelection else {
            Issue.record("The source must be pinned to the prediction account")
            return
        }

        #expect(configuration.sourceTokenSelection.isSelectionEnabled == false)
        #expect(configuration.sourceTokenSelection.allowsMarketsTokens == false)
    }

    @Test("Even if the source selector were ever opened, it would list nothing")
    func sourceSelectorOffersNothing() throws {
        let provider = try #require(makeConfiguration().sourceTokenSelection.walletsProvider as? FilteredTokenSelectorWalletsProvider)

        #expect(!provider.isIncluded(CampaignsFixtures.makeTokenSelectorItem(tokenItem: .usdcOnPolygon)))
        #expect(!provider.isIncluded(CampaignsFixtures.makeTokenSelectorItem(tokenItem: CampaignsFixtures.usdcOnEthereum)))
    }

    @Test("The destination stays selectable while markets search is off")
    func destinationIsSelectableWithoutMarkets() throws {
        let configuration = try makeConfiguration()

        #expect(configuration.receiveTokenSelection.isSelectionEnabled)
        #expect(configuration.receiveTokenSelection.allowsMarketsTokens == false)
    }

    @Test("Only USDC on Polygon passes the destination filter")
    func destinationFilterAdmitsOnlyUSDCOnPolygon() throws {
        let filter = try #require(makeConfiguration().receiveTokenSelection.walletsProvider as? FilteredTokenSelectorWalletsProvider)

        #expect(filter.isIncluded(CampaignsFixtures.makeTokenSelectorItem(tokenItem: .usdcOnPolygon)))
        #expect(!filter.isIncluded(CampaignsFixtures.makeTokenSelectorItem(tokenItem: .usdtOnPolygon)))
        #expect(!filter.isIncluded(CampaignsFixtures.makeTokenSelectorItem(tokenItem: CampaignsFixtures.usdcOnEthereum)))
    }

    @Test("The single token the flow offers to add is USDC on Polygon, held by the wallet and not by the account")
    func offersTheWalletsOwnUSDCOnPolygon() throws {
        let configuration = try makeConfiguration()
        let offered = try #require(configuration.offeredReceiveTokens.singleElement)

        #expect(offered.expressCurrency == PolymarketUtilities.usdcTokenItem.expressCurrency)
        #expect(offered != PolymarketUtilities.usdcTokenItem)
    }

    @Test("Neither side of the pair can be swapped for the other")
    func pairCannotBeReversed() throws {
        #expect(try makeConfiguration().isPairReversalEnabled == false)
    }

    @Test("A destination resolved in advance is carried into the flow as the fixed receive side")
    func carriesTheResolvedDestination() throws {
        let receiveToken = SwapableTokenStub(tokenItem: PolymarketUtilities.usdcTokenItem)
        let parameters = try makeSUT().make(withdrawingFrom: makeSource(), receiveToken: receiveToken)

        guard case .from(_, .fixed(let receive), _, _) = parameters else {
            Issue.record("A resolved destination must fix the receive side")
            return
        }

        #expect(receive.tokenItem == receiveToken.tokenItem)
    }

    @Test("Without a destination of its own the flow leaves the receive side to the user")
    func fallsBackToUserSelection() throws {
        let parameters = try makeSUT().make(withdrawingFrom: makeSource(), receiveToken: nil)

        guard case .from(_, .userSelection, _, _) = parameters else {
            Issue.record("An unresolved destination must leave the receive side open")
            return
        }
    }
}

// MARK: - What may leave the account

@Suite("Polymarket withdraw dispatcher")
struct PolymarketWithdrawTransactionDispatcherTests {
    @Test("A transfer is withdrawn for the amount and to the address it carries")
    func withdrawsTheTransferItWasGiven() async throws {
        let withdrawing = WithdrawingSpy()
        let sut = try makeSUT(withdrawing: withdrawing)

        let result = try await sut.send(transaction: .transfer(makeTransfer(amount: 12.5, destination: recipientAddress)))

        #expect(withdrawing.calls == [WithdrawingSpy.Call(amount: 12.5, recipientAddress: recipientAddress)])
        #expect(result.hash == transactionId)
    }

    @Test("A withdrawal never links to an explorer, since its hash is the transfer to the bridge and not the delivery")
    func neverLinksToAnExplorer() async throws {
        let sut = try makeSUT(withdrawing: WithdrawingSpy(transactionHash: "0x7ae1"))

        let result = try await sut.send(transaction: .transfer(makeTransfer(amount: 12.5, destination: recipientAddress)))

        #expect(result.hash == "0x7ae1")
        #expect(result.url == nil)
    }

    @Test("A provider swap is refused, since the only thing that may leave the account is the transfer")
    func refusesAProviderSwap() async throws {
        let withdrawing = WithdrawingSpy()
        let sut = try makeSUT(withdrawing: withdrawing)

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await sut.send(transaction: .cex(data: makeProviderTransactionData(), fee: makeFee()))
        }

        #expect(withdrawing.calls.isEmpty)
    }

    @Test("A refusal reaches the send flow as a failed transaction, keeping its message and carrying a code")
    func reportsARefusalAsAFailedTransaction() async throws {
        let refusal = PolymarketWithdrawTransactionService.Error.refused(.conflict(detail: nil))
        let sut = try makeSUT(withdrawing: WithdrawingSpy(failure: refusal))

        do {
            _ = try await sut.send(transaction: .transfer(makeTransfer(amount: 12.5, destination: recipientAddress)))
            Issue.record("The refusal was swallowed")
        } catch TransactionDispatcherResult.Error.sendTxError(_, let error) {
            #expect(error.localizedDescription == refusal.localizedDescription)
            #expect(error.errorCode == 112001004)
        }
    }

    @Test("A cancelled withdrawal is reported as the user's cancellation, so no alert is shown")
    func reportsACancellationAsUserCancelled() async throws {
        let sut = try makeSUT(withdrawing: WithdrawingSpy(failure: CancellationError()))

        do {
            _ = try await sut.send(transaction: .transfer(makeTransfer(amount: 12.5, destination: recipientAddress)))
            Issue.record("The cancellation was swallowed")
        } catch let error as TransactionDispatcherResult.Error {
            #expect(error.isUserCancelled)
        }
    }
}

// MARK: - Errors and states off the wire

@Suite("Polymarket withdraw wire mapping")
struct PolymarketWithdrawWireTests {
    @Test("Every status the backend documents maps to its own case", arguments: [
        (400, "badRequest"), (401, "unauthorized"), (403, "foreignDepositWallet"),
        (404, "notFound"), (409, "conflict"), (422, "relayerRejected"), (502, "upstreamUnavailable"),
    ])
    func mapsDocumentedStatuses(statusCode: Int, expected: String) {
        let error = PolymarketWithdrawError(apiError: .http(statusCode: statusCode, problemDetail: nil))

        #expect(String(describing: error).hasPrefix(expected))
    }

    @Test("An undocumented status is not mistaken for a documented one")
    func keepsAnUndocumentedStatusApart() {
        #expect(PolymarketWithdrawError(apiError: .http(statusCode: 418, problemDetail: nil)).isOther)
    }

    @Test("A state this build does not know is not mistaken for a terminal one")
    func doesNotSettleOnAnUnknownState() throws {
        struct Response: Decodable {
            let state: PolymarketWithdrawState
        }

        let json = Data(#"{ "state": "SOMETHING_NEW" }"#.utf8)
        let decoded = try JSONDecoder().decode(Response.self, from: json).state

        #expect(decoded == .unknown)
        #expect(!decoded.isTerminal)
        #expect(PolymarketWithdrawState.confirmed.isTerminal)
        #expect(PolymarketWithdrawState.failed.isTerminal)
        #expect(!PolymarketWithdrawState.inProgress.isTerminal)
    }
}

// MARK: - Fixtures

private let bridgeAddress = "0xB5b65CC112CA7D5D02581F42D73Ec0DE71A28293"
private let otherAddress = "0x2222222222222222222222222222222222222222"
private let recipientAddress = "0x3333333333333333333333333333333333333333"
private let foreignOwnerAddress = "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B"
private let sourceDepositWalletAddress = "0x9a3fce9a2b49f0b5ef1b9a3e2f4ac0b1d3e5f7a9"
private let transactionId = "0x4f2c"
private let chainCode = Data(repeating: 0x11, count: 32)

private struct StubError: Error {}

private struct SecondAttempt {
    var isRefusedAsInProgress = false
    var unexpected: String?
}

private func makeUserWalletInfo() -> UserWalletInfo {
    UserWalletInfo(
        name: "Test",
        id: UserWalletId(value: Data([0x01])),
        config: UserWalletConfigStub(supportedBlockchains: [PolymarketUtilities.blockchain]),
        backupState: .valid,
        refcode: nil,
        signerFactory: TangemSignerFactory(),
        emailDataProvider: EmailDataProviderStub()
    )
}

private extension PolymarketWithdrawTransactionServiceTests {
    struct Context {
        let sut: PolymarketWithdrawTransactionService
        let withdrawService: WithdrawServiceSpy
        let tracker = TrackerSpy()
        let bridge: BridgeServiceSpy
        let ownerAddress: String
        let depositWalletAddress: String

        init(
            ownerAddress: String? = nil,
            assets: [PolymarketSupportedAsset] = [.usdcOnPolygon],
            withdrawAddresses: PolymarketBridgeAddresses = PolymarketBridgeAddresses(addresses: [.evm: bridgeAddress]),
            submitResults: [Result<PolymarketWithdrawRecord, PolymarketWithdrawError>?] = [],
            configurationService: PolymarketConfigurationService = ConfigurationServiceStub(),
            signing: (any PolymarketBatchSigning)? = nil,
            serverClock: PolymarketServerClock = PolymarketServerClock(),
            walletStatus: PolymarketDepositWalletStatus = .readyToTrade,
            sessionHealth: PolymarketSessionHealthChecking? = nil
        ) throws {
            let cardSigner = try PolymarketCardSignerStub()
            let keysRepository = KeysRepositoryTestsMock(keys: [
                KeyInfo(
                    publicKey: cardSigner.publicKey,
                    chainCode: chainCode,
                    curve: .secp256k1,
                    isImported: false,
                    derivedKeys: [
                        PolymarketUtilities.derivationPath: ExtendedPublicKey(
                            publicKey: cardSigner.publicKey,
                            chainCode: chainCode
                        ),
                    ]
                ),
            ])

            let resolvedOwner = ownerAddress ?? {
                guard let ownerKey = PolymarketUtilities.getKey(from: keysRepository) else { return nil }

                return try? PolymarketUtilities.makeAddress(using: ownerKey)
            }()

            guard let resolvedOwner else {
                throw StubError()
            }

            let resolvedSigner: any PolymarketBatchSigning = signing
                ?? PolymarketBatchSigner(keysRepository: keysRepository, signer: cardSigner)

            let depositWallet = try PolymarketDepositWalletDeriver.derive(ownerAddress: resolvedOwner)
            let withdrawService = WithdrawServiceSpy(submitResults: submitResults)
            let bridge = BridgeServiceSpy(assets: assets, withdrawAddresses: withdrawAddresses)

            self.bridge = bridge
            self.withdrawService = withdrawService
            self.ownerAddress = resolvedOwner
            depositWalletAddress = depositWallet

            sut = PolymarketWithdrawTransactionService(
                bridgeService: bridge,
                configurationService: configurationService,
                relayerService: PolymarketRelayerServiceStub(),
                withdrawService: withdrawService,
                tracker: tracker,
                depositWalletResolver: PolymarketDepositWalletResolver(
                    walletService: PolymarketDepositWalletServiceStub(
                        status: walletStatus,
                        depositWalletAddress: depositWallet
                    ),
                    ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: resolvedOwner),
                    sessionHealth: sessionHealth
                ),
                signer: resolvedSigner,
                serverClock: serverClock,
                sessionHealth: sessionHealth
            )
        }
    }
}

private extension PolymarketWithdrawSwapParametersTests {
    func makeSUT() -> PolymarketSwapParametersFactory {
        PolymarketSwapParametersFactory(
            userWalletInfo: makeUserWalletInfo(),
            walletModelsProvider: MainScreenUIOrderedWalletModelsProvider(userWalletModel: UserWalletModelMock()),
            accountModel: PolymarketAccountModelStub(state: .active)
        )
    }

    func makeConfiguration() throws -> SwapFlowConfiguration {
        let parameters = try makeSUT().make(withdrawingFrom: makeSource(), receiveToken: nil)

        guard case .from(_, _, _, let configuration) = parameters else {
            throw StubError()
        }

        return configuration
    }

    func makeSource() throws -> PolymarketWithdrawSource {
        PolymarketWithdrawSource(
            accountModel: PolymarketAccountModelStub(state: .active),
            depositWalletAddress: sourceDepositWalletAddress,
            transactionService: makeTransactionService(),
            signer: try PolymarketCardSignerStub(),
            minimumUSD: 2
        )
    }

    func makeTransactionService() -> PolymarketWithdrawTransactionService {
        PolymarketWithdrawTransactionService(
            bridgeService: BridgeServiceSpy(assets: [.usdcOnPolygon]),
            configurationService: ConfigurationServiceStub(),
            relayerService: PolymarketRelayerServiceStub(),
            withdrawService: WithdrawServiceSpy(submitResults: []),
            tracker: TrackerSpy(),
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: PolymarketDepositWalletServiceStub(
                    status: .readyToTrade,
                    depositWalletAddress: sourceDepositWalletAddress
                ),
                ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: foreignOwnerAddress)
            ),
            signer: CancellingSignerStub(),
            serverClock: PolymarketServerClock()
        )
    }
}

private extension PolymarketWithdrawTransactionDispatcherTests {
    func makeSUT(withdrawing: WithdrawingSpy) throws -> PolymarketWithdrawTransactionDispatcher {
        PolymarketWithdrawTransactionDispatcher(
            withdrawTransactionService: withdrawing,
            signer: try PolymarketCardSignerStub()
        )
    }

    func makeTransfer(amount: Decimal, destination: String) -> BSDKTransaction {
        let blockchain = PolymarketUtilities.blockchain
        let token = BSDKToken(
            name: "USD Coin",
            symbol: "USDC",
            contractAddress: PolymarketUtilities.usdcContractAddress,
            decimalCount: 6
        )

        return BSDKTransaction(
            amount: BSDKAmount(with: blockchain, type: .token(value: token), value: amount),
            fee: makeFee(),
            sourceAddress: sourceDepositWalletAddress,
            destinationAddress: destination,
            changeAddress: sourceDepositWalletAddress
        )
    }

    func makeFee() -> BSDKFee {
        BSDKFee(BSDKAmount(with: PolymarketUtilities.blockchain, value: 0))
    }

    func makeProviderTransactionData() -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: 1,
            toAmount: 1,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: sourceDepositWalletAddress,
            destinationAddress: otherAddress,
            extraDestinationId: nil,
            txValue: 0,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: otherAddress,
            slippage: nil
        )
    }
}

private extension TokenItem {
    static let usdcOnPolygon: TokenItem = .token(
        .init(
            name: "USD Coin",
            symbol: "USDC",
            contractAddress: PolymarketUtilities.usdcContractAddress,
            decimalCount: 6,
            id: "usd-coin"
        ),
        .init(PolymarketUtilities.blockchain, derivationPath: nil)
    )

    static let usdtOnPolygon: TokenItem = .token(
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
            decimalCount: 6,
            id: "tether"
        ),
        .init(PolymarketUtilities.blockchain, derivationPath: nil)
    )
}

private extension PolymarketSupportedAsset {
    static let usdcOnPolygon = PolymarketSupportedAsset(
        chainId: "137",
        chainName: "Polygon",
        family: .evm,
        token: Token(
            name: "USDC",
            symbol: "USDC",
            address: PolymarketUtilities.usdcContractAddress,
            decimalCount: 6
        ),
        minCheckoutUSD: 2
    )
}

// MARK: - Stubs

private final class BridgeServiceSpy: PolymarketBridgeService {
    private(set) var requestedRoutes: [PolymarketWithdrawRoute] = []
    private(set) var receivedBuilderCodes: [String] = []

    let assets: [PolymarketSupportedAsset]
    let withdrawAddresses: PolymarketBridgeAddresses

    init(
        assets: [PolymarketSupportedAsset],
        withdrawAddresses: PolymarketBridgeAddresses = PolymarketBridgeAddresses(addresses: [.evm: bridgeAddress])
    ) {
        self.assets = assets
        self.withdrawAddresses = withdrawAddresses
    }

    func supportedAssets() async throws -> [PolymarketSupportedAsset] {
        assets
    }

    func fundingAddresses(forDepositWallet: String, builderCode: String) async throws -> PolymarketBridgeAddresses {
        PolymarketBridgeAddresses(addresses: [.evm: bridgeAddress])
    }

    func withdrawAddresses(
        forDepositWallet depositWalletAddress: String,
        route: PolymarketWithdrawRoute,
        builderCode: String
    ) async throws -> PolymarketBridgeAddresses {
        requestedRoutes.append(route)
        receivedBuilderCodes.append(builderCode)

        return withdrawAddresses
    }
}

private final class WithdrawingSpy: PolymarketWithdrawing {
    struct Call: Equatable {
        let amount: Decimal
        let recipientAddress: String
    }

    var calls: [Call] { state.withLock { $0 } }

    private let state = OSAllocatedUnfairLock(initialState: [Call]())
    private let failure: Error?
    private let transactionHash: String?

    init(failure: Error? = nil, transactionHash: String? = nil) {
        self.failure = failure
        self.transactionHash = transactionHash
    }

    func withdraw(amount: Decimal, to recipientAddress: String) async throws -> PolymarketWithdrawRecord {
        state.withLock { $0.append(Call(amount: amount, recipientAddress: recipientAddress)) }

        if let failure {
            throw failure
        }

        return PolymarketWithdrawRecord(transactionId: transactionId, state: .confirmed, transactionHash: transactionHash)
    }
}

private final class ConfigurationServiceStub: PolymarketConfigurationService {
    static let code = "0x" + String(repeating: "0", count: 63) + "1"

    func builderCode() async throws -> String {
        Self.code
    }
}

private final class ReentrantConfigurationServiceStub: PolymarketConfigurationService {
    private struct State {
        var onFirstCall: (@Sendable () async -> Void)?
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    func setOnFirstCall(_ operation: @escaping @Sendable () async -> Void) {
        state.withLock { $0.onFirstCall = operation }
    }

    func builderCode() async throws -> String {
        let operation = state.withLock { state -> (@Sendable () async -> Void)? in
            let operation = state.onFirstCall
            state.onFirstCall = nil
            return operation
        }

        await operation?()

        return ConfigurationServiceStub.code
    }
}

private final class FailingConfigurationServiceStub: PolymarketConfigurationService {
    func builderCode() async throws -> String {
        throw StubError()
    }
}

private struct CancellingSignerStub: PolymarketBatchSigning {
    func sign(
        _ batch: PolymarketRelayedBatch.Unsigned,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketRelayedBatch {
        throw .cancelled
    }
}

private final class TrackerSpy: PolymarketWithdrawTracking {
    struct Tracked: Equatable {
        let record: PolymarketWithdrawRecord
        let deadline: Date
    }

    var tracked: [Tracked] { state.withLock { $0 } }

    private let state = OSAllocatedUnfairLock(initialState: [Tracked]())

    func track(_ record: PolymarketWithdrawRecord, deadline: Date) async {
        state.withLock { $0.append(Tracked(record: record, deadline: deadline)) }
    }
}

private final class WithdrawServiceSpy: PolymarketWithdrawService {
    private(set) var submitted: [PolymarketRelayedBatch] = []
    private(set) var recordRequests = 0

    private var submitResults: [Result<PolymarketWithdrawRecord, PolymarketWithdrawError>?]

    init(submitResults: [Result<PolymarketWithdrawRecord, PolymarketWithdrawError>?]) {
        self.submitResults = submitResults
    }

    func submit(_ batch: PolymarketRelayedBatch) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        submitted.append(batch)

        guard !submitResults.isEmpty else {
            return accepted
        }

        switch submitResults.removeFirst() {
        case .none: return accepted
        case .success(let record): return record
        case .failure(let error): throw error
        }
    }

    func record(ofWithdrawal transactionId: String) async throws(PolymarketWithdrawError) -> PolymarketWithdrawRecord {
        recordRequests += 1

        return accepted
    }

    private var accepted: PolymarketWithdrawRecord {
        PolymarketWithdrawRecord(transactionId: transactionId, state: .inProgress, transactionHash: nil)
    }
}
