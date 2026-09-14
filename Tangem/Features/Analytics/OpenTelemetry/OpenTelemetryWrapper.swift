//
//  OpenTelemetryWrapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation
import TangemNetworkUtils
import TangemOpenTelemetry

protocol OpenTelemetryWrapper: AnyObject {
    func configure()
    func track(
        eventType: String,
        eventProperties: [String: Any]?,
        propertyOverrides: [Analytics.ParameterKey: String]
    ) -> Bool
}

final class CommonOpenTelemetryWrapper: OpenTelemetryWrapper {
    @Injected(\.geoEligibilityService) private var geoEligibilityService: GeoEligibilityService
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.openTelemetryMetricsService) private var metricsService: OpenTelemetryMetricsService

    fileprivate init() {}

    func configure() {
        guard FeatureProvider.isAvailable(.openTelemetryMetrics) else {
            return
        }

        let configuration = OTLPConfiguration(
            baseURL: Constants.baseURL,
            apiKey: keysManager.otlpApiKey,
            serviceName: Constants.serviceName,
            serviceVersion: InfoDictionaryUtils.version.value() ?? Constants.unknownVersion,
            environment: AppEnvironment.current.rawValue.lowercased(),
            osName: UIDevice.current.systemName.lowercased(),
            osVersion: UIDevice.current.systemVersion,
            language: Self.appLanguageCode,
            countryCode: Self.countryCode(geoEligibilityService.regionCode),
            session: TangemTrustEvaluatorUtil.makeSession()
        )

        metricsService.start(configuration: configuration)
    }

    func track(
        eventType: String,
        eventProperties: [String: Any]?,
        propertyOverrides: [Analytics.ParameterKey: String]
    ) -> Bool {
        guard
            metricsService.isStarted,
            let event = Analytics.Event(rawValue: eventType),
            let metric = Self.metric(for: event, properties: eventProperties, overrides: propertyOverrides)
        else {
            return false
        }

        logIfNeeded(metric)

        return metricsService.increment(metric.name, by: 1, attributes: metric.attributes)
    }

    /// The mirrored metric has no UI and its delivery is a five-minute batch, so this line is the only
    /// way to tell on a device that an event turned into the metric it was supposed to. Internal builds
    /// log too — that is what QA runs, and `.info` reaches the exportable log file there.
    private func logIfNeeded(_ metric: Metric) {
        guard AppEnvironment.current.isInternalOrDebug else {
            return
        }

        let attributes = metric.attributes
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")

        AnalyticsLogger.info("OpenTelemetry metric: \(metric.name). Attributes: {\(attributes)}")
    }

    /// Anything outside the mapping's allowlist is dropped.
    static func metric(
        for event: Analytics.Event,
        properties: [String: Any]?,
        overrides: [Analytics.ParameterKey: String] = [:]
    ) -> Metric? {
        guard
            let mapping = OpenTelemetryEventMapping.all[event],
            let coordinates = OpenTelemetryNameConverter.coordinates(for: event)
        else {
            return nil
        }

        var attributes = [Constants.categoryAttribute: coordinates.category]

        for propertyKey in mapping.allowedProperties {
            let attributeName = OpenTelemetryNameConverter.attributeName(for: propertyKey)

            guard let value = properties?[propertyKey.rawValue] else { continue }

            let exported = overrides[propertyKey] ?? value

            attributes[attributeName] = exported as? String ?? String(describing: exported)
        }

        return Metric(name: coordinates.metricName, attributes: attributes)
    }

    /// Waiting for the GeoIP lookup would cost the events recorded meanwhile, so the pipeline starts
    /// with whatever is known — usually the device region. That region is not always a country: a
    /// device set to Spanish (Latin America) reports `419`, the UN M.49 code for the macro-region, so
    /// only an ISO 3166-1 alpha-2 code passes.
    private static func countryCode(_ rawValue: String?) -> String? {
        guard let code = rawValue?.lowercased(), code.count == 2 else {
            return nil
        }

        return code.allSatisfy { $0.isASCII && $0.isLowercase } ? code : nil
    }

    private static var appLanguageCode: String? {
        Locale(identifier: Locale.appLanguageCode).language.languageCode?.identifier(.alpha2)
    }
}

// MARK: - Metric

extension CommonOpenTelemetryWrapper {
    struct Metric: Equatable {
        let name: String
        let attributes: [String: String]
    }
}

// MARK: - Dependency injection

extension InjectedValues {
    var openTelemetryWrapper: OpenTelemetryWrapper {
        get { Self[OpenTelemetryWrapperKey.self] }
        set { Self[OpenTelemetryWrapperKey.self] = newValue }
    }
}

private struct OpenTelemetryWrapperKey: InjectionKey {
    static var currentValue: OpenTelemetryWrapper = CommonOpenTelemetryWrapper()
}

// MARK: - Constants

private extension CommonOpenTelemetryWrapper {
    enum Constants {
        static let baseURL = URL(string: "https://otlp.services.tangem.org")!
        static let serviceName = "tangem-ios"
        static let unknownVersion = "unknown"
        static let categoryAttribute = "category"
    }
}
