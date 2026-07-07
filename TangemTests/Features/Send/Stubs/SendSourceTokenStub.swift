//
//  SendSourceTokenStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
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

// MARK: - SendSourceToken

final class SendSourceTokenStub: SendSourceToken {
    private let blockchain: Blockchain

    init(blockchain: Blockchain = .ton(curve: .ed25519, testnet: false)) {
        self.blockchain = blockchain
    }

    var tokenItem: TokenItem {
        .blockchain(.init(blockchain, derivationPath: nil))
    }

    var isCustom: Bool { false }
    var fiatItem: FiatItem { FiatItem(iconURL: nil, currencyCode: "USD") }
    var destination: SendReceiveTokenDestination? { nil }

    var userWalletInfo: UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signer: TangemSignerStub(),
            emailDataProvider: EmailDataProviderStub()
        )
    }

    var id: WalletModelId { WalletModelId(tokenItem: tokenItem) }
    var header: TokenHeader { .wallet(name: "Test", hasOnlyOneWallet: true) }
    var feeTokenItem: TokenItem { tokenItem }
    var defaultAddressString: String { "" }
    var availableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderStub() }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { TokenBalanceProviderStub() }
    var allowanceService: (any AllowanceService)? { nil }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { nil }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { EmailDataCollectorBuilderStub() }
    var transactionHistoryEnricher: TransactionHistoryExpressDataEnriching? { get async { nil } }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { TransactionDispatcherProviderStub() }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { nil }
    var tangemIconProvider: any TangemIconProvider { TangemIconProviderStub() }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { ConfirmTransactionPolicyStub() }
}

// MARK: - TokenBalanceProvider

struct TokenBalanceProviderStub: TokenBalanceProvider {
    let balanceType: TokenBalanceType = .loading(nil)
    let balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> = Just(.loading(nil)).eraseToAnyPublisher()
    let formattedBalanceType: FormattedTokenBalanceType = .loading(.empty("-"))
    let formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> = Just(.loading(.empty("-"))).eraseToAnyPublisher()
}

// MARK: - TangemIconProvider

private struct TangemIconProviderStub: TangemIconProvider {
    func getMainButtonIcon() -> MainButton.Icon? { nil }
}

// MARK: - ConfirmTransactionPolicy

private struct ConfirmTransactionPolicyStub: ConfirmTransactionPolicy {
    let needsHoldToConfirm: Bool = false
}

// MARK: - TransactionDispatcher

struct TransactionDispatcherStub: TransactionDispatcher {
    let hasNFCInteraction: Bool = false

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        throw NSError(domain: "stub", code: 0)
    }
}

// MARK: - TransactionDispatcherProvider

struct TransactionDispatcherProviderStub: TransactionDispatcherProvider {
    func makeTransferTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeApproveAndDEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeCEXTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeStakingTransactionDispatcher(analyticsLogger: any StakingAnalyticsLogger) -> TransactionDispatcher { TransactionDispatcherStub() }
    func makeYieldModuleTransactionDispatcher() -> TransactionDispatcher { TransactionDispatcherStub() }
}

// MARK: - EmailDataCollectorBuilder

struct EmailDataCollectorBuilderStub: EmailDataCollectorBuilder {
    func makeMailData(transaction: BSDKTransaction, isFeeIncluded: Bool, error: SendTxError) -> EmailDataCollector {
        EmailDataCollectorStub()
    }

    func makeMailData(approveTransaction: ApproveTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector {
        EmailDataCollectorStub()
    }

    func makeMailData(expressTransaction: ExpressTransactionData, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: SendTxError) -> EmailDataCollector {
        EmailDataCollectorStub()
    }

    func makeMailData(stakingActionType: StakingAction.ActionType?, target: StakingTargetInfo, isFeeIncluded: Bool, amount: BSDKAmount, fee: BSDKFee, error: UniversalError) -> EmailDataCollector {
        EmailDataCollectorStub()
    }

    func makeMailData(action: StakingTransactionAction, stakingActionType: StakingAction.ActionType?, target: StakingTargetInfo, isFeeIncluded: Bool, error: SendTxError) -> EmailDataCollector {
        EmailDataCollectorStub()
    }
}

// MARK: - EmailDataCollector

struct EmailDataCollectorStub: EmailDataCollector {
    var logData: Data? { nil }
}
