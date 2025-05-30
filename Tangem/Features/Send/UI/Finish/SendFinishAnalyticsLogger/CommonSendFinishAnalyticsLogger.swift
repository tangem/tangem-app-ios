//
//  CommonSendFinishAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSendFinishAnalyticsLogger: SendFinishAnalyticsLogger {
    private let tokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private weak var sendFeeInput: SendFeeInput?

    init(
        tokenItem: TokenItem,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        sendFeeInput: SendFeeInput
    ) {
        self.tokenItem = tokenItem
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.sendFeeInput = sendFeeInput
    }

    func onAppear() {
        let feeTypeAnalyticsParameter = feeAnalyticsParameterBuilder.analyticsParameter(
            selectedFee: sendFeeInput?.selectedFee.option
        )

        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSentScreenOpened
        default: .sendTransactionSentScreenOpened
        }

        Analytics.log(event: event, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])
    }
}
