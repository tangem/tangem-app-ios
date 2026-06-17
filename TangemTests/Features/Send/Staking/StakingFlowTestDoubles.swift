//
//  StakingFlowTestDoubles.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemExpress
import TangemFoundation
import TangemStaking
import TangemUI
@testable import Tangem

// MARK: - StakingTargetInfo

extension StakingTargetInfo {
    static func stub(address: String = "0xvault", preferred: Bool = true) -> StakingTargetInfo {
        StakingTargetInfo(
            address: address,
            name: "Validator",
            preferred: preferred,
            partner: false,
            image: nil,
            rewardType: .apr,
            rewardRate: 0,
            status: .active
        )
    }
}

// MARK: - StakingManager

final class StakingManagerMock: StakingManager {
    private let stateSubject: CurrentValueSubject<StakingManagerState, Never>

    var balances: [StakingBalance]?
    var allowanceAddress: String?
    var estimateFeeResult: Result<Decimal, Error>
    var transactionResult: Result<StakingTransactionAction, Error> = .failure(StakingManagerMockError.notStubbed)
    private(set) var sentActions: [StakingAction] = []

    init(
        state: StakingManagerState = .loading(cached: nil),
        balances: [StakingBalance]? = nil,
        allowanceAddress: String? = nil,
        estimateFeeResult: Result<Decimal, Error> = .success(0)
    ) {
        stateSubject = CurrentValueSubject(state)
        self.balances = balances
        self.allowanceAddress = allowanceAddress
        self.estimateFeeResult = estimateFeeResult
    }

    var state: StakingManagerState { stateSubject.value }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { stateSubject.eraseToAnyPublisher() }
    var updateWalletBalancesPublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var tosURL: URL { URL(string: "https://tangem.com/tos")! }
    var privacyPolicyURL: URL { URL(string: "https://tangem.com/privacy")! }

    func send(state: StakingManagerState) { stateSubject.send(state) }

    func updateState(loadActions: Bool) async {}
    func estimateFee(action: StakingAction) async throws -> Decimal { try estimateFeeResult.get() }
    func transaction(action: StakingAction) async throws -> StakingTransactionAction { try transactionResult.get() }
    func transactionDidSent(action: StakingAction) { sentActions.append(action) }
}

enum StakingManagerMockError: Error { case notStubbed }

// MARK: - SendTransactionValidator

final class SendTransactionValidatorMock: SendTransactionValidator {
    var amountError: Error?
    var amountFeeError: Error?

    func validate(amount: Amount) throws {
        if let amountError { throw amountError }
    }

    func validate(amount: Amount, fee: Fee) throws {
        if let amountFeeError { throw amountFeeError }
    }
}

// MARK: - FeeIncludedCalculator

struct FeeIncludedCalculatorStub: FeeIncludedCalculator {
    var shouldInclude: Bool = false

    func shouldIncludeFee(_ fee: Fee, into amount: Amount) -> Bool { shouldInclude }
}

// MARK: - SendAmountValidator

final class SendAmountValidatorMock: SendAmountValidator {
    var error: Error?

    func validate(amount: Decimal) throws {
        if let error { throw error }
    }
}

// MARK: - BlockchainAccountInitializationService

final class BlockchainAccountInitializationServiceMock: BlockchainAccountInitializationService {
    var isInitialized: Bool
    var initializationFee: Fee

    init(isInitialized: Bool, initializationFee: Fee) {
        self.isInitialized = isInitialized
        self.initializationFee = initializationFee
    }

    func isAccountInitialized() async throws -> Bool { isInitialized }
    func estimateInitializationFee() async throws -> Fee { initializationFee }
    func initializationTransaction(fee: Fee) -> Transaction { fatalError("Not used in tests") }
}

// MARK: - SendStakingableToken

final class SendStakingableTokenStub: SendStakingableToken {
    let blockchain: Blockchain
    private let dispatcher: TransactionDispatcher
    let transactionValidator: SendTransactionValidator
    let tokenFeeProvidersManager: TokenFeeProvidersManager
    var allowanceService: (any AllowanceService)?

    private(set) lazy var transactionDispatcherProviderStub = StakingDispatcherProviderStub(stakingDispatcher: dispatcher)

    init(
        blockchain: Blockchain = .ton(curve: .ed25519, testnet: false),
        dispatcher: TransactionDispatcher = TransactionDispatcherMock(),
        transactionValidator: SendTransactionValidator = SendTransactionValidatorMock(),
        allowanceService: (any AllowanceService)? = nil
    ) {
        self.blockchain = blockchain
        self.dispatcher = dispatcher
        self.transactionValidator = transactionValidator
        self.allowanceService = allowanceService

        let tokenItem: TokenItem = .blockchain(.init(blockchain, derivationPath: nil))
        let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(string: "0.1")!))
        let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
        tokenFeeProvidersManager = TokenFeeProvidersManagerMock(feeProvider: TokenFeeProviderStub(feeTokenItem: tokenItem, initialFee: tokenFee))
    }

    var tokenItem: TokenItem { .blockchain(.init(blockchain, derivationPath: nil)) }
    var feeTokenItem: TokenItem { tokenItem }
    var isCustom: Bool { false }
    var fiatItem: FiatItem { FiatItem(iconURL: nil, currencyCode: "USD") }
    var destination: SendReceiveTokenDestination? { nil }

    var userWalletInfo: UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(),
            refcode: nil,
            signer: TangemSignerStub(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    var id: WalletModelId { WalletModelId(tokenItem: tokenItem) }
    var header: TokenHeader { .wallet(name: "Test", hasOnlyOneWallet: true) }
    var defaultAddressString: String { "" }
    var availableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderStub() }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderStub() }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { nil }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { EmailDataCollectorBuilderStub() }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { transactionDispatcherProviderStub }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { nil }
    var tangemIconProvider: any TangemIconProvider { StakingTangemIconProviderStub() }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { StakingConfirmTransactionPolicyStub() }

    var transactionCreator: SendTransactionCreator { SendTransactionCreatorStub() }
}

final class StakingDispatcherProviderStub: TransactionDispatcherProvider {
    private let stakingDispatcher: TransactionDispatcher

    init(stakingDispatcher: TransactionDispatcher) {
        self.stakingDispatcher = stakingDispatcher
    }

    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher { stakingDispatcher }

    func makeTransferTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeCEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
}

private struct StakingTangemIconProviderStub: TangemIconProvider {
    func getMainButtonIcon() -> MainButton.Icon? { nil }
}

private struct StakingConfirmTransactionPolicyStub: ConfirmTransactionPolicy {
    let needsHoldToConfirm: Bool = false
}

private struct SendTransactionCreatorStub: SendTransactionCreator {
    func createTransaction(amount: Amount, fee: Fee, destinationAddress: String, params: TransactionParams?) async throws -> BSDKTransaction {
        fatalError("Not used in tests")
    }
}

// MARK: - StakeModelAnalyticsLogger

final class StakeModelAnalyticsLoggerMock: StakeModelAnalyticsLogger {
    func logError(_ error: any Error, currencySymbol: String) {}
    func logStakingTransactionSent(amount: SendAmount?, fee: FeeOption, signerType: String, currentProviderHost: String) {}
    func logStakingTransactionRejected(error: SendTxError) {}
}
