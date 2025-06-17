//
//  SendFeeSelectorContentViewModelAnalytics.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendFeeSelectorContentViewModelAnalytics: FeeSelectorContentViewModelAnalytics {
    let flowKind: SendModel.PredefinedValues.FlowKind
    let analyticsBuilder: FeeAnalyticsParameterBuilder

    func didSelectFeeOption(_ feeOption: FeeOption) {
        if feeOption == .custom {
            Analytics.log(.sendCustomFeeClicked)
        }

        let feeType = analyticsBuilder.analyticsParameter(selectedFee: feeOption)
        let event: Analytics.Event = switch flowKind {
        case .send, .sell, .staking: .sendFeeSelected
            // [REDACTED_TODO_COMMENT]
            // case .nft: .nftFeeSelected
        }

        Analytics.log(event: event, params: [.feeType: feeType.rawValue])
    }
}
