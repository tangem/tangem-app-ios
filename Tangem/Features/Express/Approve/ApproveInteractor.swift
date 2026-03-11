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

    private(set) var approveData: ApproveTransactionData

    // MARK: - Dependencies

    private let approveAmount: Decimal
    private let allowanceService: any AllowanceService
    private let approveTransactionDispatcher: any TransactionDispatcher
    private let tokenFeeProvidersManager: any TokenFeeProvidersManager
    private let analyticsLogger: any SendApproveAnalyticsLogger
    private weak var output: ApproveOutput?

    // MARK: - State

    private var currentPolicy: BSDKApprovePolicy
    private var recalculateApproveFeeTask: Task<Void, Never>?

    // MARK: - Init

    init(
        approveData: ApproveTransactionData,
        initialPolicy: BSDKApprovePolicy,
        approveAmount: Decimal,
        allowanceService: any AllowanceService,
        approveTransactionDispatcher: any TransactionDispatcher,
        tokenFeeProvidersManager: any TokenFeeProvidersManager,
        analyticsLogger: any SendApproveAnalyticsLogger,
        output: ApproveOutput
    ) {
        self.approveData = approveData
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
                let state = try await interactor.allowanceService.allowanceState(
                    amount: interactor.approveAmount,
                    spender: interactor.approveData.spender,
                    approvePolicy: policy,
                )

                if case .permissionRequired(let data) = state {
                    await runOnMain {
                        interactor.approveData = data
                    }

                    interactor.tokenFeeProvidersManager.update(
                        input: .approve(txData: data.txData, toContractAddress: data.toContractAddress)
                    )
                    interactor.tokenFeeProvidersManager.updateFees()
                }
            } catch is CancellationError {
                // Expected when the task is cancelled by a newer recalculation
            } catch {
                ExpressLogger.error(error: error)
            }
        }
    }

    func sendApproveTransaction() async throws {
        let fee = try tokenFeeProvidersManager.selectedTokenFee.value.get()

        analyticsLogger.logSwapButtonPermissionApprove(policy: currentPolicy)
        let result = try await approveTransactionDispatcher.send(
            transaction: .approve(data: approveData, fee: fee)
        )

        await allowanceService.markApproveTransactionSent(spender: approveData.spender)

        ExpressLogger.debug("Sent the approve transaction with signerType: \(result.signerType), host: \(result.currentHost)")
        analyticsLogger.logApproveTransactionSent(
            policy: currentPolicy,
            signerType: result.signerType,
            currentProviderHost: result.currentHost
        )

        output?.approveDidSendTransaction()
    }

    func userDidSelectFeeToken(tokenFeeProvider: any TokenFeeProvider) {
        tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: tokenFeeProvider.feeTokenItem)
        tokenFeeProvidersManager.updateFees()
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
