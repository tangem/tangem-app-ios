//
//  CommonSendApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

struct CommonSendApproveViewModelInputDataBuilder {
    private let sourceToken: SendSourceToken
    private let approveDataInput: SendApproveDataBuilderInput

    init(sourceToken: SendSourceToken, approveDataInput: SendApproveDataBuilderInput) {
        self.sourceToken = sourceToken
        self.approveDataInput = approveDataInput
    }
}

// MARK: - SendApproveViewModelInputDataBuilder

extension CommonSendApproveViewModelInputDataBuilder: SendApproveViewModelInputDataBuilder {
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

        let settings = ExpressApproveViewModel.Settings(
            subtitle: Localization.givePermissionSwapSubtitle(
                selectedProvider.name,
                sourceToken.tokenItem.currencySymbol
            ),
            feeFooterText: Localization.swapGivePermissionFeeFooter,
            tokenItem: sourceToken.tokenItem,
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
