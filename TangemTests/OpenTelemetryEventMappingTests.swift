//
//  OpenTelemetryEventMappingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Pins the mirroring contract — metric name, `category` and exported attributes — because the names
/// are derived from the event ids, so a renamed event silently renames its metric. Also guards what a
/// single entry cannot show: valid OTLP identifiers and no attribute with unbounded cardinality.
@Suite("OpenTelemetry event mapping")
struct OpenTelemetryEventMappingTests {
    @Test
    func everyRequestedMetricIsMirrored() {
        for (event, contract) in Self.expectedContracts {
            // Feeding every allowed property covers the attribute names, not just their count
            let properties = OpenTelemetryEventMapping.all[event]?.allowedProperties
                .reduce(into: [String: Any]()) { $0[$1.rawValue] = "value" }

            let metric = CommonOpenTelemetryWrapper.metric(for: event, properties: properties)

            #expect(metric != nil, "\"\(event.rawValue)\" is in the agreed scheme but is not mirrored")
            #expect(
                metric?.name == contract.metricName,
                "\"\(event.rawValue)\" is mirrored as \"\(metric?.name ?? "nil")\" instead of \"\(contract.metricName)\""
            )
            #expect(metric?.attributes["category"] == contract.category)

            let eventAttributes = Set(metric?.attributes.keys.map { $0 } ?? []).subtracting(["category"])

            #expect(eventAttributes == contract.attributes, "Exported attributes of \(event.rawValue) changed")
        }

        #expect(
            OpenTelemetryEventMapping.all.count == Self.expectedContracts.count,
            "The table mirrors metrics beyond the agreed scheme"
        )
    }

    /// Two events may share a metric name only when the category tells their series apart.
    @Test
    func metricNamesAreSnakeCaseAndSeriesAreDistinct() {
        var coordinates: Set<OpenTelemetryNameConverter.Coordinates> = []

        for event in OpenTelemetryEventMapping.all.keys {
            let derived = OpenTelemetryNameConverter.coordinates(for: event)

            #expect(derived != nil, "\"\(event.rawValue)\" has no category prefix, so it is never mirrored")

            guard let derived else { continue }

            for name in [derived.metricName, derived.category] {
                #expect(
                    name.wholeMatch(of: Self.identifierPattern) != nil,
                    "\"\(name)\" derived from \(event.rawValue) is not lowercase snake_case"
                )
            }

            #expect(coordinates.insert(derived).inserted, "\(event.rawValue) shares a series with another event")
        }
    }

    @Test
    func attributeNamesAreSnakeCase() {
        for (event, mapping) in OpenTelemetryEventMapping.all {
            for propertyKey in mapping.allowedProperties {
                let attributeName = OpenTelemetryNameConverter.attributeName(for: propertyKey)

                #expect(
                    attributeName.wholeMatch(of: Self.identifierPattern) != nil,
                    "Attribute \"\(attributeName)\" of \(event.rawValue) is not lowercase snake_case"
                )
            }
        }
    }

    @Test
    func noMappingForwardsUnboundedProperties() {
        for (event, mapping) in OpenTelemetryEventMapping.all {
            for propertyKey in mapping.allowedProperties {
                #expect(
                    !Self.forbiddenProperties.contains(propertyKey),
                    "\(event.rawValue) forwards \"\(propertyKey.rawValue)\", whose values are unbounded"
                )
            }
        }
    }

    @Test
    func propertiesOutsideTheAllowlistAreDropped() {
        let metric = CommonOpenTelemetryWrapper.metric(
            for: .transactionSent,
            properties: [
                Analytics.ParameterKey.token.rawValue: "BTC",
                Analytics.ParameterKey.blockchain.rawValue: "Bitcoin",
                Analytics.ParameterKey.memo.rawValue: "Empty",
            ]
        )

        #expect(metric?.attributes["token"] == "BTC")
        #expect(metric?.attributes[Analytics.ParameterKey.blockchain.rawValue] == nil)
        #expect(metric?.attributes["blockchain"] == nil)
        #expect(metric?.attributes["memo"] == nil)
    }

    /// The symbol of a token added by contract address is user-supplied, so it must never reach an
    /// attribute as is.
    @Test
    func customTokenOverrideReplacesTheSymbol() {
        let metric = CommonOpenTelemetryWrapper.metric(
            for: .transactionSent,
            properties: [
                Analytics.ParameterKey.token.rawValue: "WEIRDCOIN",
                Analytics.ParameterKey.feeToken.rawValue: "ETH",
            ],
            overrides: [.token: Analytics.ParameterValue.custom.rawValue]
        )

        #expect(metric?.attributes["token"] == "Custom")
        #expect(metric?.attributes["fee_token"] == "ETH")
    }

    @Test
    func unmappedEventIsNotMirrored() {
        #expect(CommonOpenTelemetryWrapper.metric(for: .signedIn, properties: nil) == nil)
    }
}

// MARK: - Test data

private extension OpenTelemetryEventMappingTests {
    static let forbiddenProperties: Set<Analytics.ParameterKey> = [
        .batch,
        .firmware,
        .error,
        .errorMessage,
        .errorDescription,
        .walletConnectDAppName,
        .walletConnectDAppUrl,
    ]

    /// Spelled out so a dropped entry fails the suite instead of quietly leaving the dashboards.
    static let expectedContracts: [Analytics.Event: Contract] = [
        .mainScreenOpened: Contract(metricName: "screen_opened", category: "main_screen", attributes: ["product_type"]),
        .walletCreatedSuccessfully: Contract(
            metricName: "wallet_created_successfully",
            category: "onboarding_create_wallet",
            attributes: ["product_type"]
        ),
        .transactionSent: Contract(
            metricName: "transaction_sent",
            category: "basic",
            attributes: ["source", "token", "fee_type", "fee_token", "fee_asset_type"]
        ),
        .swapSwapInProgressScreenOpened: Contract(
            metricName: "swap_in_progress_screen_opened",
            category: "swap",
            attributes: ["provider"]
        ),
        .swapNoticeExpressError: Contract(
            metricName: "notice_express_error",
            category: "swap",
            attributes: ["provider", "error_code"]
        ),
        .sendSwapErrorInsufficientBalance: Contract(
            metricName: "error_insufficient_balance",
            category: "token_send",
            attributes: ["send_token"]
        ),
        .onrampBuyingInProgressScreenOpened: Contract(
            metricName: "buying_in_progress_screen_opened",
            category: "onramp",
            attributes: ["provider", "payment_method"]
        ),
        .onrampErrors: Contract(
            metricName: "errors",
            category: "onramp",
            attributes: ["error_code", "token", "provider", "payment_method"]
        ),
        .stakingErrorTransactionRejected: Contract(
            metricName: "error_transaction_rejected",
            category: "staking",
            attributes: ["error_code", "token"]
        ),
        .stakingAppErrors: Contract(metricName: "app_errors", category: "staking", attributes: ["token"]),
        .marketsDataError: Contract(metricName: "data_error", category: "markets", attributes: ["error_code"]),
        .marketsChartDataError: Contract(
            metricName: "data_error",
            category: "markets_chart",
            attributes: ["error_code"]
        ),
        .walletConnectSignatureRequestFailed: Contract(
            metricName: "signature_request_failed",
            category: "wallet_connect",
            attributes: []
        ),
        .manageTokensTokenAdded: Contract(
            metricName: "token_added",
            category: "manage_tokens",
            attributes: ["source"]
        ),
        .marketsChartTokenAdded: Contract(
            metricName: "token_added",
            category: "markets_chart",
            attributes: ["source"]
        ),
        .earnTokenAdded: Contract(metricName: "token_added", category: "earn", attributes: ["source"]),
    ]

    static let identifierPattern = #/[a-z][a-z0-9]*(?:_[a-z0-9]+)*/#

    struct Contract {
        let metricName: String
        let category: String
        let attributes: Set<String>
    }
}
