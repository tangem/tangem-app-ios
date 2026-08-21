//
//  OpenTelemetryWrapper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils
import TangemOpenTelemetry

protocol OpenTelemetryWrapper: AnyObject {
    func configure()
    func track(eventType: String, eventProperties: [String: Any]?) -> Bool
}

final class CommonOpenTelemetryWrapper: OpenTelemetryWrapper {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.openTelemetryMetricsService) private var metricsService: OpenTelemetryMetricsService

    fileprivate init() {}

    func configure() {
        guard FeatureProvider.isAvailable(.openTelemetryMetrics), !AppEnvironment.current.isDebug else {
            return
        }

        let configuration = OTLPConfiguration(
            baseURL: Constants.baseURL,
            apiKey: keysManager.otlpApiKey,
            serviceName: Constants.serviceName,
            serviceVersion: InfoDictionaryUtils.version.value() ?? Constants.unknownVersion,
            environment: AppEnvironment.current.rawValue.lowercased(),
            session: TangemTrustEvaluatorUtil.makeSession()
        )

        metricsService.start(configuration: configuration)
    }

    func track(eventType: String, eventProperties: [String: Any]?) -> Bool {
        guard
            metricsService.isStarted,
            let mapping = OpenTelemetryEventMapping.all[eventType]
        else {
            return false
        }

        let attributes = attributes(from: eventProperties, mapping: mapping)

        return metricsService.increment(mapping.metricName, by: 1, attributes: attributes)
    }

    /// Anything outside the mapping's allowlist is dropped — every attribute combination is a separate
    /// series in the metrics storage, so the set must stay a reviewed list.
    private func attributes(from properties: [String: Any]?, mapping: OpenTelemetryEventMapping) -> [String: String] {
        guard let properties else { return [:] }

        return mapping.allowedProperties.reduce(into: [:]) { result, entry in
            let (propertyKey, attributeName) = entry

            guard let value = properties[propertyKey] else { return }

            result[attributeName] = value as? String ?? String(describing: value)
        }
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
    }
}
