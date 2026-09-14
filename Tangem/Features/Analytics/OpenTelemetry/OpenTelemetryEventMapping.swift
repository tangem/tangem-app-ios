//
//  OpenTelemetryEventMapping.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct OpenTelemetryEventMapping {
    /// Event property keys that may be forwarded; the attribute name is derived from the key.
    let allowedProperties: Set<Analytics.ParameterKey>

    init(allowedProperties: Set<Analytics.ParameterKey> = []) {
        self.allowedProperties = allowedProperties
    }
}

extension OpenTelemetryEventMapping {
    /// The metrics to mirror — the same set Android marks with `OtelIncludedEvent`. Every distinct
    /// attribute combination is a separate series the storage keeps forever, so the allowlists stay
    /// reviewed.
    static let all: [Analytics.Event: OpenTelemetryEventMapping] = [
        // Product Type comes from the analytics context params
        .mainScreenOpened: OpenTelemetryEventMapping(allowedProperties: [.productType]),
        .walletCreatedSuccessfully: OpenTelemetryEventMapping(allowedProperties: [.productType]),

        // Carries send, staking and gasless at once: `source` separates the flows and
        // `fee_asset_type` the gasless share, all of them a filter over one counter.
        .transactionSent: OpenTelemetryEventMapping(
            allowedProperties: [.source, .token, .feeType, .feeToken, .feeAssetType]
        ),

        .swapSwapInProgressScreenOpened: OpenTelemetryEventMapping(allowedProperties: [.provider]),
        .swapNoticeExpressError: OpenTelemetryEventMapping(allowedProperties: [.provider, .errorCode]),
        .sendSwapErrorInsufficientBalance: OpenTelemetryEventMapping(allowedProperties: [.sendToken]),

        .onrampBuyingInProgressScreenOpened: OpenTelemetryEventMapping(allowedProperties: [.provider, .paymentMethod]),
        .onrampErrors: OpenTelemetryEventMapping(allowedProperties: [.errorCode, .token, .provider, .paymentMethod]),

        .stakingErrorTransactionRejected: OpenTelemetryEventMapping(allowedProperties: [.errorCode, .token]),
        .stakingAppErrors: OpenTelemetryEventMapping(allowedProperties: [.token]),

        .marketsDataError: OpenTelemetryEventMapping(allowedProperties: [.errorCode]),
        .marketsChartDataError: OpenTelemetryEventMapping(allowedProperties: [.errorCode]),

        .walletConnectSignatureRequestFailed: OpenTelemetryEventMapping(),

        // One counter for every add; `source` is the Markets filter.
        .manageTokensTokenAdded: OpenTelemetryEventMapping(allowedProperties: [.source]),
        .marketsChartTokenAdded: OpenTelemetryEventMapping(allowedProperties: [.source]),
        .earnTokenAdded: OpenTelemetryEventMapping(allowedProperties: [.source]),
    ]
}
