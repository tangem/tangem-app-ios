//
//  CommonApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct CommonApproveViewModelInputDataBuilder {
    private let dataProvider: ApproveFlowDataProvider
    private let analyticsLogger: any SendApproveAnalyticsLogger
    private let output: ApproveOutput
    private let confirmTransactionPolicy: ConfirmTransactionPolicy

    init(
        dataProvider: ApproveFlowDataProvider,
        analyticsLogger: any SendApproveAnalyticsLogger,
        output: ApproveOutput,
        confirmTransactionPolicy: ConfirmTransactionPolicy
    ) {
        self.dataProvider = dataProvider
        self.analyticsLogger = analyticsLogger
        self.output = output
        self.confirmTransactionPolicy = confirmTransactionPolicy
    }
}

// MARK: - SendApproveViewModelInputDataBuilder

extension CommonApproveViewModelInputDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeApproveFlowFactory() throws -> ApproveFlowFactory {
        let flowInput = try dataProvider.approveFlowInput()
        let input = try buildApproveViewModelInput(from: flowInput)
        return ApproveFlowFactory(approveInput: input, confirmTransactionPolicy: confirmTransactionPolicy)
    }
}

// MARK: - Private

private extension CommonApproveViewModelInputDataBuilder {
    func buildApproveViewModelInput(from flowInput: ApproveFlowInput) throws -> ApproveViewModel.Input {
        guard let allowanceService = flowInput.sourceToken.allowanceService else {
            throw SendApproveViewModelInputDataBuilderError.notFound("AllowanceService")
        }

        let approveTransactionDispatcher = flowInput.sourceToken.transactionDispatcherProvider.makeApproveTransactionDispatcher()

        let approveInteractorState = flowInput.makeApproveInteractorState()

        let interactor = ApproveInteractor(
            approveInteractorState: approveInteractorState,
            approveAmount: flowInput.approveAmount,
            allowanceService: allowanceService,
            approveTransactionDispatcher: approveTransactionDispatcher,
            tokenFeeProvidersManager: flowInput.tokenFeeProvidersManager,
            analyticsLogger: analyticsLogger,
            output: output
        )

        let settings = ApproveViewModel.Settings(
            title: flowInput.localization.title,
            subtitle: flowInput.localization.subtitle,
            feeFooterText: flowInput.localization.feeFooterText,
            tokenItem: flowInput.sourceToken.tokenItem,
            selectedPolicy: flowInput.selectedPolicy,
            tangemIconProvider: flowInput.sourceToken.tangemIconProvider
        )

        let feeFormatter = CommonFeeFormatter()
        return ApproveViewModel.Input(
            settings: settings,
            feeFormatter: feeFormatter,
            interactor: interactor,
            supportFeeSelection: flowInput.tokenFeeProvidersManager.supportFeeSelection
        )
    }
}
