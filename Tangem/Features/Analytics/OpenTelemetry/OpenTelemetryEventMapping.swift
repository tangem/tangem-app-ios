//
//  OpenTelemetryEventMapping.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct OpenTelemetryEventMapping {
    /// snake_case, no spaces — OTLP instrument names cannot contain the spaces our event names have.
    let metricName: String
    /// Event property keys that may be forwarded, mapped to their attribute name.
    let allowedProperties: [String: String]

    init(metricName: String, allowedProperties: [String: String] = [:]) {
        self.metricName = metricName
        self.allowedProperties = allowedProperties
    }
}

extension OpenTelemetryEventMapping {
    /// The metrics to mirror, keyed by `Analytics.Event.rawValue`. Every distinct attribute
    /// combination is a separate series the storage keeps forever, so the allowlists stay reviewed.
    static let all: [String: OpenTelemetryEventMapping] = [
        Analytics.Event.mainScreenOpened.rawValue: OpenTelemetryEventMapping(
            metricName: "main_screen_opened",
            allowedProperties: [
                Analytics.ParameterKey.productType.rawValue: "product_type",
            ]
        ),

        Analytics.Event.swapSwapInProgressScreenOpened.rawValue: OpenTelemetryEventMapping(
            metricName: "swap_in_progress_screen_opened",
            allowedProperties: [
                Analytics.ParameterKey.provider.rawValue: "provider",
            ]
        ),

        Analytics.Event.swapNoticeExpressError.rawValue: OpenTelemetryEventMapping(
            metricName: "swap_express_error",
            allowedProperties: [
                Analytics.ParameterKey.provider.rawValue: "provider",
                Analytics.ParameterKey.errorCode.rawValue: "error_code",
            ]
        ),

        Analytics.Event.onrampBuyingInProgressScreenOpened.rawValue: OpenTelemetryEventMapping(
            metricName: "onramp_in_progress_screen_opened",
            allowedProperties: [
                Analytics.ParameterKey.provider.rawValue: "provider",
                Analytics.ParameterKey.paymentMethod.rawValue: "payment_method",
            ]
        ),

        Analytics.Event.onrampErrors.rawValue: OpenTelemetryEventMapping(
            metricName: "onramp_error",
            allowedProperties: [
                Analytics.ParameterKey.errorCode.rawValue: "error_code",
                Analytics.ParameterKey.token.rawValue: "token",
                Analytics.ParameterKey.provider.rawValue: "provider",
                Analytics.ParameterKey.paymentMethod.rawValue: "payment_method",
            ]
        ),

        // Carries send, staking and gasless at once: `source` separates the flows and
        // `fee_asset_type` the gasless share, all of them a filter over one counter.
        Analytics.Event.transactionSent.rawValue: OpenTelemetryEventMapping(
            metricName: "transaction_sent",
            allowedProperties: [
                Analytics.ParameterKey.source.rawValue: "source",
                Analytics.ParameterKey.token.rawValue: "token",
                Analytics.ParameterKey.feeType.rawValue: "fee_type",
                Analytics.ParameterKey.feeToken.rawValue: "fee_token",
                Analytics.ParameterKey.feeAssetType.rawValue: "fee_asset_type",
            ]
        ),

        Analytics.Event.stakingErrorTransactionRejected.rawValue: OpenTelemetryEventMapping(
            metricName: "staking_transaction_rejected",
            allowedProperties: [
                Analytics.ParameterKey.errorCode.rawValue: "error_code",
                Analytics.ParameterKey.token.rawValue: "token",
            ]
        ),

        Analytics.Event.stakingAppErrors.rawValue: OpenTelemetryEventMapping(
            metricName: "staking_app_error",
            allowedProperties: [
                Analytics.ParameterKey.token.rawValue: "token",
            ]
        ),

        Analytics.Event.walletCreatedSuccessfully.rawValue: OpenTelemetryEventMapping(
            metricName: "wallet_created",
            allowedProperties: [
                Analytics.ParameterKey.productType.rawValue: "product_type",
                Analytics.ParameterKey.creationType.rawValue: "creation_type",
            ]
        ),

        Analytics.Event.sendSwapErrorInsufficientBalance.rawValue: OpenTelemetryEventMapping(
            metricName: "send_insufficient_balance_error",
            allowedProperties: [
                Analytics.ParameterKey.sendToken.rawValue: "send_token",
            ]
        ),

        // One counter for every add; `source` is the Markets filter.
        Analytics.Event.manageTokensTokenAdded.rawValue: OpenTelemetryEventMapping(
            metricName: "manage_tokens_token_added",
            allowedProperties: [
                Analytics.ParameterKey.source.rawValue: "source",
            ]
        ),

        Analytics.Event.marketsDataError.rawValue: OpenTelemetryEventMapping(
            metricName: "markets_data_error",
            allowedProperties: [
                Analytics.ParameterKey.errorCode.rawValue: "error_code",
            ]
        ),

        Analytics.Event.walletConnectSignatureRequestFailed.rawValue: OpenTelemetryEventMapping(
            metricName: "wc_signature_request_failed"
        ),
    ]
}
