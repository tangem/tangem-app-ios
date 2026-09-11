//
//  CommonOpenTelemetryMetricsService.swift
//  TangemOpenTelemetry
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetryProtocolExporterCommon
import OpenTelemetryProtocolExporterHttp
import OpenTelemetrySdk
import PersistenceExporter
import TangemFoundation
import TangemLogger
import UIKit

public final class CommonOpenTelemetryMetricsService: OpenTelemetryMetricsService {
    private let protectedState = OSAllocatedUnfairLock(initialState: State())

    public init() {}

    public var isStarted: Bool {
        protectedState { $0.pipeline != nil }
    }

    // MARK: - Lifecycle

    public func start(configuration: OTLPConfiguration) {
        guard protectedState({ $0.pipeline == nil }) else {
            OTLPLogger.warning("Already started, ignoring repeated start")
            return
        }

        OpenTelemetry.registerFeedbackHandler { OTLPLogger.warning($0) }

        let pipeline = Self.makePipeline(configuration: configuration, storageURL: Self.defaultStorageURL())

        let started = protectedState { state in
            guard state.pipeline == nil else { return false }

            state.pipeline = pipeline
            state.backgroundObserver = makeBackgroundObserver()

            return true
        }

        guard started else {
            _ = pipeline.provider.shutdown()
            return
        }

        OTLPLogger.info("Started, exporting every \(Int(configuration.exportInterval))s")
    }

    static func makePipeline(configuration: OTLPConfiguration, storageURL: URL?) -> Pipeline {
        let exporter = makeExporter(configuration: configuration, storageURL: storageURL)

        let reader = PeriodicMetricReaderBuilder(exporter: exporter)
            .setInterval(timeInterval: configuration.exportInterval)
            .build()

        let resource = Resource(attributes: [
            SemanticConventions.Service.name.rawValue: .string(configuration.serviceName),
            SemanticConventions.Service.version.rawValue: .string(configuration.serviceVersion),
            SemanticConventions.Deployment.environmentName.rawValue: .string(configuration.environment),
        ])

        // `ViewRegistry.findViews()` only consults explicitly registered views — it never falls back
        // to the per-instrument defaults it builds in its own initializer. Without this catch-all
        // view the SDK registers no storage, and every recorded value is silently discarded while
        // the pipeline still reports success.
        let provider = MeterProviderSdk.builder()
            .setResource(resource: resource)
            .registerView(selector: InstrumentSelector.builder().build(), view: View.builder().build())
            .registerMetricReader(reader: reader)
            .build()

        let meter = provider
            .meterBuilder(name: Constants.scopeName)
            .setInstrumentationVersion(instrumentationVersion: Constants.scopeVersion)
            .build()

        return Pipeline(provider: provider, meter: meter, exporter: exporter)
    }

    // MARK: - Recording

    @discardableResult
    public func increment(_ name: String, by value: Int = 1, attributes: [String: String] = [:]) -> Bool {
        let counter: LongCounterSdk? = protectedState { state in
            guard let meter = state.pipeline?.meter else { return nil }

            let counter = state.counters[name] ?? meter.counterBuilder(name: name).setUnit("1").build()
            state.counters[name] = counter

            return counter
        }

        guard let counter else { return false }

        counter.add(value: value, attributes: attributes.mapValues { AttributeValue.string($0) })

        return true
    }

    // MARK: - Delivery

    func flush() {
        protectedState { $0.pipeline }?.flush()
    }

    // MARK: - Pipeline

    private static func makeExporter(configuration: OTLPConfiguration, storageURL: URL?) -> MetricExporter {
        let exporter = OtlpHttpMetricExporter(
            endpoint: configuration.metricsURL,
            config: OtlpConfiguration(
                timeout: configuration.timeout,
                compression: .gzip,
                headers: [(Constants.apiKeyHeader, configuration.apiKey)]
            ),
            // Every install of the app reports into the same series: attributes deliberately carry
            // no per-device identifier, so cumulative totals from different installs would overwrite
            // one another in the storage instead of summing — delta increments add up.
            aggregationTemporalitySelector: AggregationTemporality.alwaysDelta(),
            httpClient: BaseHTTPClient(session: configuration.session),
            envVarHeaders: nil
        )

        guard let storageURL else {
            OTLPLogger.warning("No storage directory, batches will not survive a restart")
            return exporter
        }

        do {
            try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)

            // The library's default preset fits as is: a batch is a few KB every five minutes and
            // anything older than 18 h is purged, so the spool stays megabytes-sized regardless.
            return try PersistenceMetricExporterDecorator(
                metricExporter: exporter,
                storageURL: storageURL
            )
        } catch {
            OTLPLogger.error("Failed to set up persistence, falling back to direct delivery", error: error)
            return exporter
        }
    }

    static func defaultStorageURL() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appending(path: Constants.storageDirectory, directoryHint: .isDirectory)
    }

    private func makeBackgroundObserver() -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flushBeforeSuspension()
        }
    }

    private func flushBeforeSuspension() {
        let backgroundTask = BackgroundTaskWrapper(taskName: Constants.backgroundTaskName)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.flush()
            backgroundTask.finish()
        }
    }
}

// MARK: - Auxiliary types

extension CommonOpenTelemetryMetricsService {
    struct Pipeline {
        let provider: MeterProviderSdk
        let meter: MeterSdk
        let exporter: MetricExporter

        func flush() {
            _ = provider.forceFlush()
            _ = exporter.flush()
        }
    }
}

private extension CommonOpenTelemetryMetricsService {
    struct State {
        var pipeline: Pipeline?
        var counters: [String: LongCounterSdk] = [:]
        var backgroundObserver: NSObjectProtocol?
    }

    enum Constants {
        static let scopeName = "tangem.business"
        static let scopeVersion = "1"
        static let apiKeyHeader = "x-api-key"
        static let storageDirectory = "OTLPPendingBatches"
        static let backgroundTaskName = "OTLPFlush"
    }
}
