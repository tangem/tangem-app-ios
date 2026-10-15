//
//  ApproveInteractor.swift
//  Tangem
//
//  Created on 2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemMacro

final class ApproveInteractor {
    // MARK: - Publishers

    var approveFeePublisher: AnyPublisher<TokenFee, Never> {
        tokenFeeProvidersManager.selectedTokenFeePublisher
    }

    // MARK: - Dependencies

    private let approveAmount: Decimal
    private let allowanceService: any AllowanceService
    private let approveTransactionDispatcher: any TransactionDispatcher
    private let tokenFeeProvidersManager: any TokenFeeProvidersManager
    private let analyticsLogger: any SendApproveAnalyticsLogger
    private weak var output: ApproveOutput?

    // MARK: - State

    private(set) var approveInteractorState: ApproveInteractorState

    // MARK: - Init

    init(
        approveInteractorState: ApproveInteractorState,
        approveAmount: Decimal,
        allowanceService: any AllowanceService,
        approveTransactionDispatcher: any TransactionDispatcher,
        tokenFeeProvidersManager: any TokenFeeProvidersManager,
        analyticsLogger: any SendApproveAnalyticsLogger,
        output: ApproveOutput
    ) {
        self.approveInteractorState = approveInteractorState
        self.approveAmount = approveAmount
        self.allowanceService = allowanceService
        self.approveTransactionDispatcher = approveTransactionDispatcher
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        self.analyticsLogger = analyticsLogger
        self.output = output

        tokenFeeProvidersManager.update(input: approveInteractorState.feeInput)
        tokenFeeProvidersManager.updateFees()
    }

    // MARK: - Public

    func logPermissionScreenOpened() {
        analyticsLogger.logPermissionScreenOpened(isRevoke: approveInteractorState.isRevokeAndApprove)
    }

    @MainActor
    func updateApprovePolicy(policy: BSDKApprovePolicy) async throws {
        let approveData = try await allowanceService.makeApproveData(
            spender: approveInteractorState.approveData.spender,
            amount: approveAmount,
            policy: policy
        )

        try Task.checkCancellation()

        let newState = approveInteractorState.replacingApprove(data: approveData, policy: policy)
        approveInteractorState = newState
        tokenFeeProvidersManager.update(input: newState.feeInput)

        await tokenFeeProvidersManager.updateFees().value
    }

    @MainActor
    func sendApproveTransaction() async throws {
        switch approveInteractorState {
        case .approve(let data, let policy):
            try await sendApprove(data: data, policy: policy)
        case .revokeAndApprove(let revoke, let approve, let feeUnit, let policy):
            try await sendRevokeAndApprove(revokeData: revoke, approveData: approve, feeUnit: feeUnit, policy: policy)
        }
    }

    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: tokenFeeProvider.feeTokenItem)
        tokenFeeProvidersManager.updateFees()
    }
}

// MARK: - Private

private extension ApproveInteractor {
    func sendApprove(data: ApproveTransactionData, policy: BSDKApprovePolicy) async throws {
        let fee = try tokenFeeProvidersManager.selectedTokenFee.value.get()

        analyticsLogger.logSwapButtonPermissionApprove(policy: policy)
        let result = try await approveTransactionDispatcher.send(
            transaction: .approve(data: data, fee: fee)
        )

        await allowanceService.markApproveTransactionSent(spender: data.spender)

        ExpressLogger.info("Sent the approve transaction with signerType: \(result.signerType), host: \(result.currentHost)")
        analyticsLogger.logApproveTransactionSent(
            policy: policy,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
        )

        output?.approveDidSendTransaction()
    }

    /// Sends revoke (approve to 0) then approve in one batch.
    /// Required for tokens like USDT on Ethereum that need allowance reset to zero first.
    func sendRevokeAndApprove(
        revokeData: ApproveTransactionData,
        approveData: ApproveTransactionData,
        feeUnit: BSDKFee,
        policy: BSDKApprovePolicy
    ) async throws {
        ExpressLogger.info("Sending revoke+approve batch for spender: \(approveData.spender)")

        // feeUnit is the 1x revoke fee estimate.
        // Approve tx needs ~2x the gas, so we double gasLimit and amount.
        // Revoke+approve only applies to EVM tokens (e.g. USDT on Ethereum).
        guard let ethParams = feeUnit.parameters as? (any EthereumFeeParameters) else {
            assertionFailure("Revoke+approve flow requires EthereumFeeParameters, got \(type(of: feeUnit.parameters))")
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let revokeFee = feeUnit
        let bufferedParams = ethParams.changingGasLimit(to: ethParams.gasLimit * 2)
        var bufferedAmount = feeUnit.amount
        bufferedAmount.value *= 2
        let approveFee = BSDKFee(bufferedAmount, parameters: bufferedParams)

        let transactions: [TransactionDispatcherTransactionType] = [
            .approve(data: revokeData, fee: revokeFee),
            .approve(data: approveData, fee: approveFee),
        ]

        analyticsLogger.logSwapButtonPermissionApprove(policy: policy)

        let results = try await approveTransactionDispatcher.send(transactions: transactions)

        await allowanceService.markApproveTransactionSent(spender: approveData.spender)

        if let result = results.last {
            ExpressLogger.info("Sent the revoke+approve transactions with signerType: \(result.signerType), host: \(result.currentHost)")
            analyticsLogger.logApproveTransactionSent(
                policy: policy,
                signerType: result.signerType,
                currentProviderHost: result.currentHost
            )
        }

        output?.approveDidSendTransaction()
    }
}

// MARK: - ApproveInteractorState

extension ApproveInteractor {
    @CaseFlagable
    enum ApproveInteractorState {
        case approve(data: ApproveTransactionData, policy: BSDKApprovePolicy)
        /// - `feeUnit`: 1x revoke fee estimate, used to build individual tx fees at send time
        case revokeAndApprove(revoke: ApproveTransactionData, approve: ApproveTransactionData, feeUnit: Fee, policy: BSDKApprovePolicy)

        var policy: BSDKApprovePolicy {
            switch self {
            case .approve(_, let policy):
                return policy
            case .revokeAndApprove(_, _, _, let policy):
                return policy
            }
        }

        var approveData: ApproveTransactionData {
            switch self {
            case .approve(let data, _):
                return data
            case .revokeAndApprove(_, let data, _, _):
                return data
            }
        }

        func replacingApprove(data: ApproveTransactionData, policy: BSDKApprovePolicy) -> ApproveInteractorState {
            switch self {
            case .approve:
                return .approve(data: data, policy: policy)
            case .revokeAndApprove(let revoke, _, let feeUnit, _):
                return .revokeAndApprove(revoke: revoke, approve: data, feeUnit: feeUnit, policy: policy)
            }
        }

        /// Fee input derived from this state. For revoke+approve, fee is estimated against the
        /// revoke tx because the node can't simulate a non-zero approve when on-chain allowance
        /// is already non-zero (USDT will revert).
        var feeInput: TokenFeeProviderInputData {
            switch self {
            case .approve(let data, _):
                .approve(txData: data.txData, toContractAddress: data.toContractAddress)
            case .revokeAndApprove(let revoke, _, _, _):
                .approve(txData: revoke.txData, toContractAddress: revoke.toContractAddress, feeMultiplier: .triple)
            }
        }
    }
}

// MARK: - FeeSelectorTokensDataProvider

extension ApproveInteractor: FeeSelectorTokensDataProvider {
    var selectedTokenFeeProvider: any TokenFeeProvider {
        tokenFeeProvidersManager.selectedFeeProvider
    }

    var selectedTokenFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        tokenFeeProvidersManager.selectedFeeProviderPublisher
    }

    var supportedTokenFeeProviders: [any TokenFeeProvider] {
        tokenFeeProvidersManager.tokenFeeProviders.filter { $0.state.isSupported }
    }

    var supportedTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        let providers = tokenFeeProvidersManager.tokenFeeProviders

        return Publishers.MergeMany(providers.map(\.statePublisher))
            .map { _ in providers.filter { $0.state.isSupported } }
            .prepend(providers.filter { $0.state.isSupported })
            .removeDuplicates(by: { $0.map(\.feeTokenItem) == $1.map(\.feeTokenItem) })
            .eraseToAnyPublisher()
    }
}
