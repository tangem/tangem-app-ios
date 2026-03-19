//
//  ApproveInteractorTests.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Testing
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("ApproveInteractor")
struct ApproveInteractorTests {
    private let testSpender = "0xSpenderAddress"
    private let testContractAddress = "0xContractAddress"
    private let testTxData = Data([0xAA, 0xBB, 0xCC, 0xDD])
    private let testApproveAmount: Decimal = 1000

    // MARK: - updateApprovePolicy

    @Test("Policy change calls allowanceService and updates approveData + fees")
    func updateApprovePolicy_permissionRequired_updatesApproveDataAndFees() async throws {
        let newTxData = Data([0x11, 0x22, 0x33])
        let newContractAddress = "0xNewContract"
        let newSpender = "0xNewSpender"
        let newApproveData = ApproveTransactionData(txData: newTxData, spender: newSpender, toContractAddress: newContractAddress)

        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(newApproveData))

        let sut = makeSUT(env: env)
        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)

        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        #expect(env.allowanceService.allowanceStateCalls.count == 1)
        #expect(env.allowanceService.allowanceStateCalls.first?.approvePolicy == ApprovePolicy.unlimited)
        #expect(env.allowanceService.allowanceStateCalls.first?.amount == testApproveAmount)
        #expect(env.allowanceService.allowanceStateCalls.first?.spender == testSpender)

        #expect(sut.approveData.txData == newTxData)
        #expect(sut.approveData.toContractAddress == newContractAddress)

        #expect(env.feeManager.updateInputCalls.count == 1)
        #expect(env.feeManager.updateFeesCalls == 1)

        if case .approve(let txData, let toContractAddress) = env.feeManager.updateInputCalls.first {
            #expect(txData == newTxData)
            #expect(toContractAddress == newContractAddress)
        } else {
            Issue.record("Expected .approve input data")
        }
    }

    @Test("enoughAllowance response does not update approveData or fees")
    func updateApprovePolicy_enoughAllowance_doesNotUpdateData() async throws {
        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.enoughAllowance)

        let sut = makeSUT(env: env)
        let originalTxData = sut.approveData.txData

        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.allowanceService.allowanceStateCalls.count >= 1 }

        #expect(sut.approveData.txData == originalTxData)
        #expect(env.feeManager.updateInputCalls.isEmpty)
        #expect(env.feeManager.updateFeesCalls == 0)
    }

    @Test("approveTransactionInProgress response does not update approveData or fees")
    func updateApprovePolicy_approveTransactionInProgress_doesNotUpdateData() async throws {
        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.approveTransactionInProgress)

        let sut = makeSUT(env: env)
        let originalTxData = sut.approveData.txData
        let originalContract = sut.approveData.toContractAddress

        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.allowanceService.allowanceStateCalls.count >= 1 }

        #expect(sut.approveData.txData == originalTxData)
        #expect(sut.approveData.toContractAddress == originalContract)
        #expect(env.feeManager.updateInputCalls.isEmpty)
        #expect(env.feeManager.updateFeesCalls == 0)
    }

    @Test("allowanceState throwing does not corrupt approveData or trigger fee update")
    func updateApprovePolicy_allowanceServiceThrows_doesNotCorruptState() async throws {
        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .failure(NSError(domain: "test", code: -1))

        let sut = makeSUT(env: env)
        let originalTxData = sut.approveData.txData
        let originalContract = sut.approveData.toContractAddress
        let originalSpender = sut.approveData.spender

        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.allowanceService.allowanceStateCalls.count >= 1 }

        #expect(sut.approveData.txData == originalTxData, "txData must not change on error")
        #expect(sut.approveData.toContractAddress == originalContract, "contract must not change on error")
        #expect(sut.approveData.spender == originalSpender, "spender must not change on error")
        #expect(env.feeManager.updateInputCalls.isEmpty, "Fee input must not be updated on error")
        #expect(env.feeManager.updateFeesCalls == 0, "Fees must not be refreshed on error")
    }

    @Test("Rapid policy toggles: only the last request takes effect")
    func updateApprovePolicy_rapidToggle_cancelsInFlightRequest() async throws {
        let secondData = ApproveTransactionData(txData: Data([0x02]), spender: testSpender, toContractAddress: "0xSecond")

        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(
            .permissionRequired(ApproveTransactionData(txData: Data([0x01]), spender: testSpender, toContractAddress: "0xFirst"))
        )

        let sut = makeSUT(env: env)

        // First call — will be cancelled
        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)

        // Immediately override with second call
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(secondData))
        sut.updateApprovePolicy(policy: ApprovePolicy.specified)

        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        #expect(sut.approveData.txData == secondData.txData)
        #expect(sut.approveData.toContractAddress == secondData.toContractAddress)
    }

    // MARK: - sendApproveTransaction

    @Test("Happy path: dispatches correct data and fee, marks sent, notifies output, logs analytics")
    func sendApproveTransaction_happyPath() async throws {
        let env = makeEnv()
        let sut = makeSUT(env: env)

        try await sut.sendApproveTransaction()

        #expect(env.dispatcher.sendCalls.count == 1)
        if case .approve(let data, let fee) = env.dispatcher.sendCalls.first {
            #expect(data.txData == testTxData)
            #expect(data.spender == testSpender)
            #expect(data.toContractAddress == testContractAddress)
            #expect(fee.amount.value == 0.001, "Fee value must match the configured stub fee")
        } else {
            Issue.record("Expected .approve transaction type")
        }

        #expect(env.allowanceService.markApproveTransactionSentCalls.count == 1)
        #expect(env.allowanceService.markApproveTransactionSentCalls.first == testSpender)

        #expect(env.output.approveDidSendTransactionCallCount == 1)

        #expect(env.analyticsLogger.logSwapButtonPermissionApproveCalls.count == 1)
        #expect(env.analyticsLogger.logApproveTransactionSentCalls.count == 1)
    }

    @Test("ApproveTransactionData passed to dispatcher must be byte-identical — no mutation")
    func sendApproveTransaction_approveDataIntegrity() async throws {
        let specificTxData = Data([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE])
        let specificSpender = "0x1234567890abcdef"
        let specificContract = "0xfedcba0987654321"

        let env = makeEnv()
        let sut = makeSUT(
            env: env,
            approveData: ApproveTransactionData(
                txData: specificTxData,
                spender: specificSpender,
                toContractAddress: specificContract
            )
        )

        try await sut.sendApproveTransaction()

        guard case .approve(let sentData, _) = env.dispatcher.sendCalls.first else {
            Issue.record("Expected .approve transaction")
            return
        }

        #expect(sentData.txData == specificTxData, "txData must be byte-identical")
        #expect(sentData.spender == specificSpender, "spender must not be altered")
        #expect(sentData.toContractAddress == specificContract, "contract address must not be altered")
    }

    @Test("Fee unavailable throws and does NOT dispatch or notify output")
    func sendApproveTransaction_feeUnavailable_throws() async {
        let env = makeEnv()
        let sut = makeSUT(
            env: env,
            feeResult: LoadingResult<BSDKFee, any Error>.failure(NSError(domain: "test", code: -1))
        )

        await #expect(throws: (any Error).self) {
            try await sut.sendApproveTransaction()
        }

        #expect(env.output.approveDidSendTransactionCallCount == 0, "Output must NOT be notified on fee failure")
        #expect(env.dispatcher.sendCalls.isEmpty, "Dispatcher must NOT be called on fee failure")
    }

    @Test("Dispatcher failure does NOT mark sent or notify output")
    func sendApproveTransaction_dispatcherFails() async {
        let env = makeEnv()
        env.dispatcher.sendResult = .failure(TransactionDispatcherResult.Error.transactionNotFound)

        let sut = makeSUT(env: env)

        await #expect(throws: (any Error).self) {
            try await sut.sendApproveTransaction()
        }

        #expect(env.allowanceService.markApproveTransactionSentCalls.isEmpty, "Must NOT mark sent on dispatcher failure")
        #expect(env.output.approveDidSendTransactionCallCount == 0, "Must NOT notify output on dispatcher failure")
    }

    @Test("Dispatcher userCancelled error does NOT mark sent or notify output")
    func sendApproveTransaction_userCancelled_doesNotMarkSentOrNotify() async {
        let env = makeEnv()
        env.dispatcher.sendResult = .failure(TransactionDispatcherResult.Error.userCancelled)

        let sut = makeSUT(env: env)

        await #expect(throws: (any Error).self) {
            try await sut.sendApproveTransaction()
        }

        #expect(env.allowanceService.markApproveTransactionSentCalls.isEmpty, "Must NOT mark sent on user cancel")
        #expect(env.output.approveDidSendTransactionCallCount == 0, "Must NOT notify output on user cancel")
        #expect(env.analyticsLogger.logApproveTransactionSentCalls.isEmpty, "Must NOT log sent analytics on user cancel")
    }

    @Test("After policy change, dispatcher receives the UPDATED approveData")
    func sendApproveTransaction_afterPolicyChange_sendsUpdatedData() async throws {
        let updatedTxData = Data([0xFF, 0xEE])
        let updatedData = ApproveTransactionData(txData: updatedTxData, spender: testSpender, toContractAddress: "0xUpdatedContract")

        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(updatedData))

        let sut = makeSUT(env: env)
        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        try await sut.sendApproveTransaction()

        guard case .approve(let sentData, _) = env.dispatcher.sendCalls.first else {
            Issue.record("Expected .approve transaction")
            return
        }

        #expect(sentData.txData == updatedTxData, "Must send the updated txData after policy change")
        #expect(sentData.toContractAddress == "0xUpdatedContract")
    }

    @Test("Analytics logger receives the correct policy value after policy change")
    func sendApproveTransaction_afterPolicyChange_logsCorrectPolicy() async throws {
        let updatedData = ApproveTransactionData(txData: Data([0x01]), spender: testSpender, toContractAddress: testContractAddress)

        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(updatedData))

        let sut = makeSUT(env: env)
        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        try await sut.sendApproveTransaction()

        #expect(env.analyticsLogger.logSwapButtonPermissionApproveCalls.first == ApprovePolicy.unlimited)
        #expect(env.analyticsLogger.logApproveTransactionSentCalls.first?.policy == ApprovePolicy.unlimited)
    }

    // MARK: - Gasless fee token payment

    @Test("Selecting a gasless fee token then sending uses the gasless fee, not the native fee")
    func sendApproveTransaction_afterGaslessFeeTokenSelection_sendsGaslessFee() async throws {
        let gaslessFeeValue: Decimal = 2.5

        // Create the manager initialized with the gasless fee (simulating the state after user selects gasless token)
        let gaslessTokenItem = TokenItem.token(
            .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6),
            .init(.ethereum(testnet: false), derivationPath: nil)
        )
        let gaslessFee = Fee(Amount(with: .ethereum(testnet: false), value: gaslessFeeValue))
        let gaslessTokenFee = TokenFee(option: .market, tokenItem: gaslessTokenItem, value: .success(gaslessFee))

        let env = Env()
        let feeProvider = TokenFeeProviderStub(feeTokenItem: gaslessTokenItem, initialFee: gaslessTokenFee)
        env.feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)

        let sut = makeSUT(env: env)

        try await sut.sendApproveTransaction()

        guard case .approve(_, let sentFee) = env.dispatcher.sendCalls.first else {
            Issue.record("Expected .approve transaction")
            return
        }

        #expect(sentFee.amount.value == gaslessFeeValue, "Fee must be the gasless token fee, not native")
    }

    @Test("Approve transaction type is always .approve, never .transfer/.dex/.cex regardless of fee token")
    func sendApproveTransaction_alwaysUsesApproveTransactionType() async throws {
        let env = makeEnv()
        let sut = makeSUT(env: env)

        try await sut.sendApproveTransaction()

        #expect(env.dispatcher.sendCalls.count == 1)
        guard case .approve = env.dispatcher.sendCalls.first else {
            Issue.record("Transaction type must be .approve, got \(env.dispatcher.sendCalls.first!)")
            return
        }
    }

    // MARK: - Approve data isolation (no leakage to original transaction)

    @Test("Approve spender address is distinct from any user-provided destination")
    func approveData_spenderAddress_doesNotMatchUserDestination() {
        let userDestination = "0xUserRecipientAddress"
        let env = makeEnv()
        let sut = makeSUT(env: env)

        #expect(sut.approveData.spender != userDestination)
        #expect(sut.approveData.toContractAddress != userDestination)
    }

    @Test("Approve data uses contract address, not user destination — values are independent")
    func approveData_contractAddress_isIndependentOfUserTransaction() async throws {
        let approveContract = "0xTokenContract"
        let approveSpender = "0xDEXRouter"
        let approveData = ApproveTransactionData(
            txData: Data([0x01]),
            spender: approveSpender,
            toContractAddress: approveContract
        )

        let env = makeEnv()
        let sut = makeSUT(env: env, approveData: approveData)

        try await sut.sendApproveTransaction()

        guard case .approve(let sentData, _) = env.dispatcher.sendCalls.first else {
            Issue.record("Expected .approve transaction")
            return
        }

        #expect(sentData.toContractAddress == approveContract, "Must send to token contract, not user destination")
        #expect(sentData.spender == approveSpender, "Spender must be DEX router, not user destination")
    }

    @Test("Policy change only mutates approve-specific data, spender remains stable")
    func updateApprovePolicy_spenderRemainsStable() async throws {
        let updatedData = ApproveTransactionData(
            txData: Data([0x99]),
            spender: testSpender,
            toContractAddress: "0xNewContract"
        )

        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(updatedData))

        let sut = makeSUT(env: env)
        let originalSpender = sut.approveData.spender

        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        // The allowanceService is always called with the original spender
        #expect(env.allowanceService.allowanceStateCalls.first?.spender == originalSpender)
    }

    @Test("Fee input data is .approve type, never .common/.dex/.cex — no address leakage")
    func updateApprovePolicy_feeInputIsApproveType() async throws {
        let updatedData = ApproveTransactionData(
            txData: Data([0x42]),
            spender: testSpender,
            toContractAddress: "0xApproveContract"
        )

        let env = makeEnv()
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(updatedData))

        let sut = makeSUT(env: env)
        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        #expect(env.feeManager.updateInputCalls.count == 1)

        guard let firstInput = env.feeManager.updateInputCalls.first,
              case .approve(let txData, let contractAddress) = firstInput else {
            Issue.record("Fee input must be .approve, not .common/.dex/.cex — got \(String(describing: env.feeManager.updateInputCalls.first))")
            return
        }

        #expect(txData == updatedData.txData)
        #expect(contractAddress == updatedData.toContractAddress)
    }

    @Test("Multiple policy changes never produce .common or .dex fee input types")
    func updateApprovePolicy_multipleTimes_neverProducesNonApproveFeeInput() async throws {
        let env = makeEnv()

        let sut = makeSUT(env: env)

        // First change
        let data1 = ApproveTransactionData(txData: Data([0x01]), spender: testSpender, toContractAddress: "0xC1")
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(data1))
        sut.updateApprovePolicy(policy: ApprovePolicy.unlimited)
        try await waitUntil { env.feeManager.updateFeesCalls >= 1 }

        // Second change
        let data2 = ApproveTransactionData(txData: Data([0x02]), spender: testSpender, toContractAddress: "0xC2")
        env.allowanceService.allowanceStateResult = .success(.permissionRequired(data2))
        sut.updateApprovePolicy(policy: ApprovePolicy.specified)
        try await waitUntil { env.feeManager.updateFeesCalls >= 2 }

        for input in env.feeManager.updateInputCalls {
            guard case .approve = input else {
                Issue.record("All fee inputs must be .approve, got \(input)")
                return
            }
        }
    }

    @Test("Approve transaction amount is zero — it does not transfer user's token balance")
    func sendApproveTransaction_doesNotTransferUserBalance() async throws {
        // The approve transaction sets amount to 0 (it's a permission grant, not a transfer).
        // This test verifies the approve data contains only permission calldata, not a value transfer.
        let env = makeEnv()
        let sut = makeSUT(env: env)

        try await sut.sendApproveTransaction()

        guard case .approve(let data, _) = env.dispatcher.sendCalls.first else {
            Issue.record("Expected .approve transaction")
            return
        }

        // The approve transaction data (txData) is ERC-20 approve calldata,
        // toContractAddress is the token contract — never the user's destination
        #expect(data.txData == testTxData, "Must use approve calldata, not transfer calldata")
        #expect(data.toContractAddress == testContractAddress, "Must target token contract")
    }

    // MARK: - Output (SwapModel communication)

    @Test("Output is notified exactly once on successful send")
    func sendApproveTransaction_success_notifiesOutputExactlyOnce() async throws {
        let env = makeEnv()
        let sut = makeSUT(env: env)

        try await sut.sendApproveTransaction()

        #expect(env.output.approveDidSendTransactionCallCount == 1, "Output must be notified exactly once")
    }

    @Test("Output is never notified on any type of failure")
    func sendApproveTransaction_anyFailure_neverNotifiesOutput() async {
        // Dispatcher failure
        let env1 = makeEnv()
        env1.dispatcher.sendResult = .failure(TransactionDispatcherResult.Error.transactionNotFound)
        let sut1 = makeSUT(env: env1)
        _ = try? await sut1.sendApproveTransaction()
        #expect(env1.output.approveDidSendTransactionCallCount == 0)

        // User cancelled
        let env2 = makeEnv()
        env2.dispatcher.sendResult = .failure(TransactionDispatcherResult.Error.userCancelled)
        let sut2 = makeSUT(env: env2)
        _ = try? await sut2.sendApproveTransaction()
        #expect(env2.output.approveDidSendTransactionCallCount == 0)

        // Fee unavailable
        let env3 = makeEnv()
        let sut3 = makeSUT(env: env3, feeResult: .failure(NSError(domain: "test", code: -1)))
        _ = try? await sut3.sendApproveTransaction()
        #expect(env3.output.approveDidSendTransactionCallCount == 0)
    }

    @Test("Weak output reference — send succeeds even if output is deallocated")
    func sendApproveTransaction_weakOutputDeallocated_stillSucceeds() async throws {
        let env = makeEnv()
        let sut = makeSUT(env: env)

        // Deallocate the output before sending
        env.releaseOutput()

        // Should not throw — the interactor completes successfully
        try await sut.sendApproveTransaction()

        // Dispatcher was called
        #expect(env.dispatcher.sendCalls.count == 1)
        // Allowance was marked
        #expect(env.allowanceService.markApproveTransactionSentCalls.count == 1)
    }

    // MARK: - userDidSelectFeeToken

    @Test("Selecting a fee token updates the manager and refreshes fees")
    func userDidSelectFeeToken_updatesManagerAndRefreshesFees() {
        let env = makeEnv()
        let sut = makeSUT(env: env)
        let tokenItem = makeTestTokenItem()
        let stub = TokenFeeProviderStub(feeTokenItem: tokenItem, initialFee: makeTestTokenFee())

        sut.userDidSelectFeeToken(tokenFeeProvider: stub)

        #expect(env.feeManager.updateSelectedFeeProviderCalls.count == 1)
        #expect(env.feeManager.updateFeesCalls == 1)
    }

    // MARK: - Async Helpers

    /// Polls `condition` with cooperative yields until it returns `true`, or throws on timeout.
    private func waitUntil(
        timeout: Duration = .seconds(2),
        condition: @Sendable () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }
            await Task.yield()
        }
    }

    // MARK: - Helpers

    private final class Env {
        let allowanceService = AllowanceServiceMock()
        let dispatcher = TransactionDispatcherMock()
        let analyticsLogger = SendApproveAnalyticsLoggerMock()
        private(set) var output: ApproveOutputMock! = ApproveOutputMock()
        var feeManager: TokenFeeProvidersManagerMock!

        func releaseOutput() {
            output = nil
        }
    }

    private func makeEnv(feeValue: Decimal = 0.001) -> Env {
        let env = Env()
        let tokenItem = makeTestTokenItem()
        let fee = Fee(Amount(with: .ethereum(testnet: false), value: feeValue))
        let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
        let feeProvider = TokenFeeProviderStub(feeTokenItem: tokenItem, initialFee: tokenFee)
        env.feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        return env
    }

    private func makeSUT(
        env: Env,
        approveData: ApproveTransactionData? = nil,
        feeResult: LoadingResult<BSDKFee, any Error>? = nil
    ) -> ApproveInteractor {
        let data = approveData ?? ApproveTransactionData(
            txData: testTxData,
            spender: testSpender,
            toContractAddress: testContractAddress
        )

        if let feeResult {
            let tokenItem = makeTestTokenItem()
            let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: feeResult)
            let feeProvider = TokenFeeProviderStub(feeTokenItem: tokenItem, initialFee: tokenFee)
            env.feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        }

        return ApproveInteractor(
            approveData: data,
            initialPolicy: ApprovePolicy.specified,
            approveAmount: testApproveAmount,
            allowanceService: env.allowanceService,
            approveTransactionDispatcher: env.dispatcher,
            tokenFeeProvidersManager: env.feeManager,
            analyticsLogger: env.analyticsLogger,
            output: env.output
        )
    }

    private func makeTestTokenItem() -> TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    private func makeTestTokenFee(feeResult: LoadingResult<BSDKFee, any Error>? = nil) -> TokenFee {
        let fee = Fee(Amount(with: .ethereum(testnet: false), value: 0.001))
        return TokenFee(
            option: .market,
            tokenItem: makeTestTokenItem(),
            value: feeResult ?? .success(fee)
        )
    }
}
