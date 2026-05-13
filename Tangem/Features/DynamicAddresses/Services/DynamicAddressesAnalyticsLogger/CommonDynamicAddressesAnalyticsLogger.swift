//
//  CommonDynamicAddressesAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

final class CommonDynamicAddressesAnalyticsLogger: DynamicAddressesAnalyticsLogger {
    private let tokenItem: TokenItem
    private var hasLoggedNotEnoughFeeNotice = false

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func logDynamicAddressesScreenOpened() {
        Analytics.log(event: .dynamicAddressesScreenOpened, params: baseParams)
    }

    func logButtonEnableDynamicAddresses() {
        Analytics.log(event: .buttonEnableDynamicAddresses, params: baseParams)
    }

    func logDynamicAddressesEnabled() {
        Analytics.log(event: .dynamicAddressesEnabled, params: baseParams)
    }

    func logButtonDisableDynamicAddresses() {
        Analytics.log(event: .buttonDisableDynamicAddresses, params: baseParams)
    }

    func logDynamicAddressesDisabled() {
        Analytics.log(event: .dynamicAddressesDisabled, params: baseParams)
    }

    func logDynamicAddressesNoticeUnavailable() {
        Analytics.log(event: .dynamicAddressesNoticeUnavailable, params: baseParams)
    }

    func logDynamicAddressesErrorUnavailable() {
        Analytics.log(event: .dynamicAddressesErrorUnavailable, params: baseParams)
    }

    func logTokenNoticeNotEnoughFee() {
        guard !hasLoggedNotEnoughFeeNotice else { return }
        hasLoggedNotEnoughFeeNotice = true

        var params = baseParams
        params[.source] = Analytics.ParameterValue.dynamicAddressesSourceDynamicAddresses.rawValue
        Analytics.log(event: .tokenNoticeNotEnoughFee, params: params)
    }

    // [REDACTED_TODO_COMMENT]
    func logDynamicAddressesNoticeFundsFound() {
        Analytics.log(event: .dynamicAddressesNoticeFundsFound, params: baseParams)
    }

    private var baseParams: [Analytics.ParameterKey: String] {
        [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ]
    }
}
