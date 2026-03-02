//
//  CommonSendApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

struct CommonSendApproveViewModelInputDataBuilder {
    private let sourceTokenInput: SendSourceTokenInput
    private let approveDataInput: SendApproveDataBuilderInput
    private let tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding

    init(
        sourceTokenInput: SendSourceTokenInput,
        approveDataInput: SendApproveDataBuilderInput,
        tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.approveDataInput = approveDataInput
        self.tokenFeeManagerProviding = tokenFeeManagerProviding
    }
}

// MARK: - SendApproveViewModelInputDataBuilder

extension CommonSendApproveViewModelInputDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeApproveFlowFactory() throws -> ExpressApproveFlowFactory {
        let input = try makeExpressApproveViewModelInput()
        let sourceToken = try sourceTokenInput.sourceToken.get()
        return ExpressApproveFlowFactory(
            approveInput: input,
            tokenFeeManagerProviding: tokenFeeManagerProviding,
            allowanceService: sourceToken.allowanceService,
            approveAmount: approveDataInput.approveAmount,
            spender: approveDataInput.approveSpender
        )
    }

    func makeExpressApproveViewModelInput() throws -> ExpressApproveViewModel.Input {
        guard let selectedPolicy = approveDataInput.approveRequestedWithSelectedPolicy else {
            throw SendMailDataBuilderError.notFound("Selected approve policy")
        }

        guard let selectedProvider = approveDataInput.approveRequestedByExpressProvider else {
            throw SendMailDataBuilderError.notFound("Selected provider")
        }

        guard let approveViewModelInput = approveDataInput.approveViewModelInput else {
            throw SendMailDataBuilderError.notFound("ApproveViewModelInput")
        }

        let sourceToken = try sourceTokenInput.sourceToken.get()
        let settings = ExpressApproveViewModel.Settings(
            subtitle: Localization.givePermissionSwapSubtitle(
                selectedProvider.name,
                sourceToken.tokenItem.currencySymbol
            ),
            feeFooterText: Localization.swapGivePermissionFeeFooter,
            tokenItem: sourceToken.tokenItem,
            feeTokenItem: sourceToken.feeTokenItem,
            selectedPolicy: selectedPolicy,
            tangemIconProvider: CommonTangemIconProvider(config: sourceToken.userWalletInfo.config)
        )

        let feeFormatter = CommonFeeFormatter()

        return ExpressApproveViewModel.Input(
            settings: settings,
            feeFormatter: feeFormatter,
            approveViewModelInput: approveViewModelInput
        )
    }
}
