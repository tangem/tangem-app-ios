//
//  SendDestinationAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendDestinationAnalyticsLogger {
    let tokenItem: TokenItem

    func log(isAddressValid: Bool, source: Analytics.DestinationAddressSource) {
        let event: Analytics.Event = switch tokenItem.token?.metadata.kind {
        case .nonFungible: .nftSendAddressEntered
        default: .sendAddressEntered
        }

        Analytics.logDestinationAddress(event: event, isAddressValid: isAddressValid, source: source)
    }
}
