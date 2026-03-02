//
//  CommonStakingApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

struct CommonStakingApproveViewModelInputDataBuilder {
    private let sourceToken: SendSourceToken
    private let approveDataInput: SendApproveDataBuilderInput
    private let tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding

    init(
        sourceToken: SendSourceToken,
        approveDataInput: SendApproveDataBuilderInput,
        tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding
    ) {
        self.sourceToken = sourceToken
        self.approveDataInput = approveDataInput
        self.tokenFeeManagerProviding = tokenFeeManagerProviding
    }
}

// MARK: - SendApproveViewModelInputDataBuilder

extension CommonStakingApproveViewModelInputDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeApproveFlowFactory() throws -> ExpressApproveFlowFactory {
        let input = try makeExpressApproveViewModelInput()
        return ExpressApproveFlowFactory(
            approveInput: input,
            tokenFeeManagerProviding: tokenFeeManagerProviding,
            allowanceService: sourceToken.allowanceService,
            approveAmount: nil,
            spender: nil
        )
    }

    func makeExpressApproveViewModelInput() throws -> ExpressApproveViewModel.Input {
        guard let selectedPolicy = approveDataInput.approveRequestedWithSelectedPolicy else {
            throw SendMailDataBuilderError.notFound("Selected approve policy")
        }

        guard let approveViewModelInput = approveDataInput.approveViewModelInput else {
            throw SendMailDataBuilderError.notFound("ApproveViewModelInput")
        }

        let settings = ExpressApproveViewModel.Settings(
            subtitle: Localization.givePermissionStakingSubtitle(sourceToken.tokenItem.currencySymbol),
            feeFooterText: Localization.stakingGivePermissionFeeFooter,
            tokenItem: sourceToken.tokenItem,
            feeTokenItem: sourceToken.feeTokenItem,
            selectedPolicy: selectedPolicy,
            tangemIconProvider: CommonTangemIconProvider(config: sourceToken.userWalletInfo.config)
        )

        let feeFormatter = CommonFeeFormatter()

        return ExpressApproveViewModel.Input(
            settings: settings,
            feeFormatter: feeFormatter,
            approveViewModelInput: approveViewModelInput,
        )
    }
}
