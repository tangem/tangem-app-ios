//
//  ApproveInteractor.swift
//  Tangem
//
//  Created on 2026.
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation

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
    private var currentPolicy: BSDKApprovePolicy
    private var recalculateApproveFeeTask: Task<Void, Never>?

    // MARK: - Init

    init(
        approveInteractorState: ApproveInteractorState,
        initialPolicy: BSDKApprovePolicy,
        approveAmount: Decimal,
        allowanceService: any AllowanceService,
        approveTransactionDispatcher: any TransactionDispatcher,
        tokenFeeProvidersManager: any TokenFeeProvidersManager,
        analyticsLogger: any SendApproveAnalyticsLogger,
        output: ApproveOutput
    ) {
        self.approveInteractorState = approveInteractorState
        currentPolicy = initialPolicy
        self.approveAmount = approveAmount
        self.allowanceService = allowanceService
        self.approveTransactionDispatcher = approveTransactionDispatcher
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        self.analyticsLogger = analyticsLogger
        self.output = output
    }

    deinit {
        recalculateApproveFeeTask?.cancel()
    }

    // MARK: - Public

    func updateApprovePolicy(policy: BSDKApprovePolicy) {
        currentPolicy = policy

        recalculateApproveFeeTask?.cancel()
        recalculateApproveFeeTask = runTask(in: self) { interactor in
            do {
                let allowanceResult = try await interactor.allowanceService.allowanceState(
                    amount: interactor.approveAmount,
                    spender: interactor.approveInteractorState.approveData.spender,
                    approvePolicy: policy,
                )

                try Task.checkCancellation()

                guard let newState = interactor.makeApproveInteractorState(from: allowanceResult) else {
                    return
                }

                await runOnMain {
                    interactor.approveInteractorState = newState
                }

                interactor.tokenFeeProvidersManager.update(input: newState.feeInput)
                interactor.tokenFeeProvidersManager.updateFees()
            } catch is CancellationError {
                // Expected: superseded by a newer recalculation
            } catch {
                ExpressLogger.error(error: error)
            }
        }
    }

    func sendApproveTransaction() async throws {
        switch approveInteractorState {
        case .approve(let data):
            try await sendApprove(data: data)
        case .revokeAndApprove(let revoke, let approve, let feeUnit):
            try await sendRevokeAndApprove(revokeData: revoke, approveData: approve, feeUnit: feeUnit)
        }
    }

    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: tokenFeeProvider.feeTokenItem)
        tokenFeeProvidersManager.updateFees()
    }
}

// MARK: - Private

private extension ApproveInteractor {
    func makeApproveInteractorState(from result: AllowanceState) -> ApproveInteractorState? {
        switch result {
        case .permissionRequired(let data):
            return .approve(data: data)
        case .revokeAndPermissionRequired(let revoke, let approve):
            if case .revokeAndApprove(_, _, let feeUnit) = approveInteractorState {
                return .revokeAndApprove(revoke: revoke, approve: approve, feeUnit: feeUnit)
            }
            assertionFailure("Unexpected state transition to revokeAndApprove")
            return .approve(data: approve)
        default:
            return nil
        }
    }

    func sendApprove(data: ApproveTransactionData) async throws {
        let fee = try tokenFeeProvidersManager.selectedTokenFee.value.get()

        analyticsLogger.logSwapButtonPermissionApprove(policy: currentPolicy)
        let result = try await approveTransactionDispatcher.send(
            transaction: .approve(data: data, fee: fee)
        )

        await allowanceService.markApproveTransactionSent(spender: data.spender)

        ExpressLogger.debug("Sent the approve transaction with signerType: \(result.signerType), host: \(result.currentHost)")
        analyticsLogger.logApproveTransactionSent(
            policy: currentPolicy,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
        )

        output?.approveDidSendTransaction()
    }

    /// Sends revoke (approve to 0) then approve in one batch.
    /// Required for tokens like USDT on Ethereum that need allowance reset to zero first.
    func sendRevokeAndApprove(revokeData: ApproveTransactionData, approveData: ApproveTransactionData, feeUnit: BSDKFee) async throws {
        ExpressLogger.debug("Sending revoke+approve batch for spender: \(approveData.spender)")

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

        analyticsLogger.logSwapButtonPermissionApprove(policy: currentPolicy)

        let results = try await approveTransactionDispatcher.send(transactions: transactions)

        await allowanceService.markApproveTransactionSent(spender: approveData.spender)

        if let result = results.last {
            ExpressLogger.debug("Sent the revoke+approve transactions with signerType: \(result.signerType), host: \(result.currentHost)")
            analyticsLogger.logApproveTransactionSent(
                policy: currentPolicy,
                signerType: result.signerType,
                currentProviderHost: result.currentHost
            )
        }

        output?.approveDidSendTransaction()
    }
}

// MARK: - ApproveInteractorState

extension ApproveInteractor {
    enum ApproveInteractorState {
        case approve(data: ApproveTransactionData)
        /// - `feeUnit`: 1x revoke fee estimate, used to build individual tx fees at send time
        case revokeAndApprove(revoke: ApproveTransactionData, approve: ApproveTransactionData, feeUnit: Fee)

        var approveData: ApproveTransactionData {
            switch self {
            case .approve(let data):
                return data
            case .revokeAndApprove(_, let approve, _):
                return approve
            }
        }

        /// Fee input derived from this state. For revoke+approve, fee is estimated against the
        /// revoke tx because the node can't simulate a non-zero approve when on-chain allowance
        /// is already non-zero (USDT will revert).
        var feeInput: TokenFeeProviderInputData {
            switch self {
            case .approve(let data):
                .approve(txData: data.txData, toContractAddress: data.toContractAddress)
            case .revokeAndApprove(let revoke, _, _):
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
