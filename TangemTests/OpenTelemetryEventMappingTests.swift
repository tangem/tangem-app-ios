//
//  OpenTelemetryEventMappingTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Guards what cannot be seen by reading a single entry of the mirroring table: names must be valid
/// OTLP identifiers, and no attribute may carry a value with unbounded cardinality.
@Suite("OpenTelemetry event mapping")
struct OpenTelemetryEventMappingTests {
    private static let forbiddenProperties: Set<String> = [
        Analytics.ParameterKey.batch.rawValue,
        Analytics.ParameterKey.firmware.rawValue,
        Analytics.ParameterKey.error.rawValue,
        Analytics.ParameterKey.errorMessage.rawValue,
        Analytics.ParameterKey.errorDescription.rawValue,
        Analytics.ParameterKey.walletConnectDAppName.rawValue,
        Analytics.ParameterKey.walletConnectDAppUrl.rawValue,
    ]

    /// Spelled out so a dropped entry fails the suite instead of quietly leaving the dashboards.
    private static let expectedMetricNames: [Analytics.Event: String] = [
        .mainScreenOpened: "main_screen_opened",
        .swapSwapInProgressScreenOpened: "swap_in_progress_screen_opened",
        .swapNoticeExpressError: "swap_express_error",
        .onrampBuyingInProgressScreenOpened: "onramp_in_progress_screen_opened",
        .onrampErrors: "onramp_error",
        .transactionSent: "transaction_sent",
        .stakingErrorTransactionRejected: "staking_transaction_rejected",
        .stakingAppErrors: "staking_app_error",
        .walletCreatedSuccessfully: "wallet_created",
        .sendSwapErrorInsufficientBalance: "send_insufficient_balance_error",
        .manageTokensTokenAdded: "manage_tokens_token_added",
        .marketsDataError: "markets_data_error",
        .walletConnectSignatureRequestFailed: "wc_signature_request_failed",
    ]

    private static let identifierPattern = #/[a-z][a-z0-9]*(?:_[a-z0-9]+)*/#

    @Test
    func everyKeyIsAKnownAnalyticsEvent() {
        for eventType in OpenTelemetryEventMapping.all.keys {
            #expect(
                Analytics.Event(rawValue: eventType) != nil,
                "\"\(eventType)\" is not an Analytics.Event, so nothing will ever be mirrored under it"
            )
        }
    }

    @Test
    func metricNamesAreSnakeCaseAndUnique() {
        let names = OpenTelemetryEventMapping.all.values.map(\.metricName)

        for name in names {
            #expect(
                name.wholeMatch(of: Self.identifierPattern) != nil,
                "Metric name \"\(name)\" is not lowercase snake_case"
            )
        }

        #expect(Set(names).count == names.count, "Two events map to the same metric name, their counts would merge")
    }

    @Test
    func attributeNamesAreSnakeCase() {
        for (eventType, mapping) in OpenTelemetryEventMapping.all {
            for attributeName in mapping.allowedProperties.values {
                #expect(
                    attributeName.wholeMatch(of: Self.identifierPattern) != nil,
                    "Attribute \"\(attributeName)\" of \(eventType) is not lowercase snake_case"
                )
            }
        }
    }

    @Test
    func noMappingForwardsUnboundedProperties() {
        for (eventType, mapping) in OpenTelemetryEventMapping.all {
            for propertyKey in mapping.allowedProperties.keys {
                #expect(
                    !Self.forbiddenProperties.contains(propertyKey),
                    "\(eventType) forwards \"\(propertyKey)\", whose values are unbounded"
                )
            }
        }
    }

    @Test
    func everyRequestedMetricIsMirrored() {
        for (event, metricName) in Self.expectedMetricNames {
            let mapping = OpenTelemetryEventMapping.all[event.rawValue]

            #expect(mapping != nil, "\"\(event.rawValue)\" is in the agreed scheme but is not mirrored")
            #expect(
                mapping?.metricName == metricName,
                "\"\(event.rawValue)\" is mirrored as \"\(mapping?.metricName ?? "nil")\" instead of \"\(metricName)\""
            )
        }

        #expect(
            OpenTelemetryEventMapping.all.count == Self.expectedMetricNames.count,
            "The table mirrors metrics beyond the agreed scheme"
        )
    }

    /// A key that is not a real parameter name never matches the event payload, so the attribute
    /// would silently never be set.
    @Test
    func everyAllowedPropertyIsAKnownParameterKey() {
        for (eventType, mapping) in OpenTelemetryEventMapping.all {
            for propertyKey in mapping.allowedProperties.keys {
                #expect(
                    Analytics.ParameterKey(rawValue: propertyKey) != nil,
                    "\(eventType) allows \"\(propertyKey)\", which is not an Analytics.ParameterKey"
                )
            }
        }
    }

    @Test
    func contextAttributesCoverTheDeviceDimensions() {
        let attributes = OpenTelemetryContextAttributes.all

        #expect(attributes["platform"] == "iOS")
        #expect(attributes["os_name"]?.isEmpty == false)
        #expect(attributes["os_version"]?.isEmpty == false)
        #expect(attributes["language"]?.isEmpty == false)

        for attributeName in attributes.keys {
            #expect(
                attributeName.wholeMatch(of: Self.identifierPattern) != nil,
                "Context attribute \"\(attributeName)\" is not lowercase snake_case"
            )
        }
    }

    /// Both sets share one namespace, so a collision would overwrite a device dimension.
    @Test
    func contextAttributesDoNotCollideWithEventAttributes() {
        let contextNames = Set(OpenTelemetryContextAttributes.all.keys)

        for (eventType, mapping) in OpenTelemetryEventMapping.all {
            for attributeName in mapping.allowedProperties.values {
                #expect(
                    !contextNames.contains(attributeName),
                    "\(eventType) maps a property onto \"\(attributeName)\", which is a device dimension"
                )
            }
        }
    }
}
