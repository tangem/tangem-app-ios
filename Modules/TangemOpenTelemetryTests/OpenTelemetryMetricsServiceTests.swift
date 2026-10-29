//
//  OpenTelemetryMetricsServiceTests.swift
//  TangemOpenTelemetryTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetryProtocolExporterCommon
import OpenTelemetrySdk
import SwiftProtobuf
import TangemFoundation
import Testing
@testable import TangemOpenTelemetry

@Suite("OTLP pipeline wiring", .serialized)
struct OpenTelemetryMetricsServiceTests {
    /// `ViewRegistry.findViews()` never falls back to the default views it builds in its own
    /// initializer, so a provider without an explicit view records nothing while still reporting
    /// success — a green build with no data. This fails if the catch-all view is ever dropped.
    @Test("A recorded value actually reaches the exporter")
    func catchAllViewIsRegistered() async throws {
        StubURLProtocol.reset()
        let pipeline = makePipeline()
        defer { _ = pipeline.provider.shutdown() }

        pipeline.meter.counterBuilder(name: "tangem_probe_total").build().add(value: 1)
        pipeline.flush()

        _ = try #require(await waitForRequest(), "No request was issued — the catch-all view is missing")
    }

    @Test("Flushing delivers over the network rather than only to disk")
    func flushLeavesTheDevice() async throws {
        StubURLProtocol.reset()
        let pipeline = makePipeline()
        defer { _ = pipeline.provider.shutdown() }

        pipeline.meter.counterBuilder(name: "tangem_probe_total").build().add(value: 1)
        _ = pipeline.provider.forceFlush()

        #expect(StubURLProtocol.snapshot().isEmpty, "Collecting alone is expected to stop at the spool")

        pipeline.flush()

        _ = try #require(await waitForRequest(), "Flush left the batch on disk instead of sending it")
    }

    @Test("Request carries the API key, gzip and the metrics path")
    func requestShape() async throws {
        StubURLProtocol.reset()
        let pipeline = makePipeline()
        defer { _ = pipeline.provider.shutdown() }

        pipeline.meter.counterBuilder(name: "tangem_transaction_sent_total").build()
            .add(value: 14, attributes: ["blockchain": .string("ethereum")])
        pipeline.flush()

        let captured = try #require(await waitForRequest())

        #expect(captured.request.httpMethod == "POST")
        #expect(captured.request.url?.absoluteString == "https://otlp.example.com/v1/metrics")
        #expect(captured.request.value(forHTTPHeaderField: "x-api-key") == "test-key")
        #expect(captured.request.value(forHTTPHeaderField: "Content-Encoding") == "gzip")

        let body = try #require(captured.body)
        #expect(body.prefix(3) == Data([0x1F, 0x8B, 0x08]), "Body is not gzip framed")
    }

    @Test("Configuration appends the OTLP metrics path to the base endpoint")
    func metricsURL() {
        let configuration = OTLPConfiguration(
            baseURL: URL(string: "https://otlp.example.com")!,
            apiKey: "k",
            serviceName: "tangem-ios",
            serviceVersion: "6.0",
            environment: "production",
            osName: "ios",
            osVersion: "18.0",
            language: "en",
            countryCode: "us",
            session: makeSession()
        )

        #expect(configuration.metricsURL.absoluteString == "https://otlp.example.com/v1/metrics")
    }

    /// The resource is the only place a metric could pick up a user identifier, so its attribute set
    /// is pinned: app coordinates, the OS, the app language and the coarse country, nothing else.
    @Test
    func resourceCarriesTheSharedDimensionsAndNothingElse() {
        let pipeline = makePipeline()
        defer { _ = pipeline.provider.shutdown() }

        let attributes = pipeline.resource.attributes

        #expect(
            Set(attributes.keys) == [
                "service.name",
                "service.version",
                "deployment.environment.name",
                "os.name",
                "os.version",
                "language",
                "country_code",
            ]
        )
        #expect(attributes["language"] == .string("de"))
        #expect(attributes["country_code"] == .string("de"))
    }

    @Test
    func unresolvedLanguageOrCountryStaysOutOfTheResource() {
        let pipeline = makePipeline(language: nil, countryCode: nil)
        defer { _ = pipeline.provider.shutdown() }

        let attributes = pipeline.resource.attributes

        #expect(Set(attributes.keys) == ["service.name", "service.version", "deployment.environment.name", "os.name", "os.version"])
    }
}

// MARK: - Histograms

extension OpenTelemetryMetricsServiceTests {
    @Test
    func bucketSetsArePinned() {
        #expect(OpenTelemetryHistogramBuckets.main.boundaries == [250, 500, 1000, 2000, 5000, 10000, 30000])
        #expect(OpenTelemetryHistogramBuckets.short.boundaries == [250, 500, 1000, 3000, 10000])
    }

    @Test(
        "Histogram reaches the network with its own bounds, with and without the spool",
        arguments: [OpenTelemetryHistogramBuckets.main, .short],
        [false, true]
    )
    func histogramBoundsSurviveExport(buckets: OpenTelemetryHistogramBuckets, spooled: Bool) async throws {
        StubURLProtocol.reset()
        let service = makeService(spooled: spooled)

        #expect(service.record("tangem_probe_loaded", milliseconds: 700, buckets: buckets))
        service.flush()

        let captured = try #require(await waitForRequests(1).first)
        let metric = try #require(metrics(in: captured, named: "tangem_probe_loaded").first)
        let point = try #require(metric.histogram.dataPoints.first)

        #expect(metric.unit == "ms")
        #expect(point.explicitBounds == buckets.boundaries)
        try #require(point.bucketCounts.count == buckets.boundaries.count + 1)
        #expect(point.bucketCounts[2] == 1)
        #expect(point.count == 1)
    }

    @Test("Delta export cycles do not carry earlier values over")
    func histogramDeltaCycles() async throws {
        StubURLProtocol.reset()
        let service = makeService()

        service.record("tangem_probe_loaded", milliseconds: 100, buckets: .main)
        service.flush()
        _ = try #require(await waitForRequest())

        service.record("tangem_probe_loaded", milliseconds: 7000, buckets: .main)
        service.flush()
        let requests = await waitForRequests(2)
        try #require(requests.count == 2)

        let points = try metrics(in: requests[1], named: "tangem_probe_loaded").flatMap { $0.histogram.dataPoints }
        let point = try #require(points.first)

        #expect(points.count == 1)
        #expect(point.count == 1)
        #expect(point.sum == 7000)
        #expect(point.bucketCounts == [0, 0, 0, 0, 0, 1, 0, 0])
    }

    @Test
    func histogramKeepsTheBucketsItWasCreatedWith() {
        let service = makeService()

        #expect(service.record("tangem_probe_loaded", milliseconds: 100, buckets: .main))
        #expect(!service.record("tangem_probe_loaded", milliseconds: 100, buckets: .short))
        #expect(service.record("tangem_probe_loaded", milliseconds: 100, buckets: .main))
    }

    @Test("A value the spool cannot encode is rejected and does not take the batch down with it")
    func nonFiniteOrNegativeValuesAreRejected() async throws {
        StubURLProtocol.reset()
        let service = makeService()

        #expect(!service.record("tangem_probe_loaded", milliseconds: .nan, buckets: .main))
        #expect(!service.record("tangem_probe_loaded", milliseconds: .infinity, buckets: .main))
        #expect(!service.record("tangem_probe_loaded", milliseconds: -1, buckets: .main))

        service.increment("tangem_probe_total", by: 1)
        service.flush()

        let captured = try #require(await waitForRequest())
        #expect(try metrics(in: captured, named: "tangem_probe_total").count == 1)
        #expect(try metrics(in: captured, named: "tangem_probe_loaded").isEmpty)
    }

    @Test
    func recordingBeforeStartIsRejected() {
        #expect(!CommonOpenTelemetryMetricsService().record("tangem_probe_loaded", milliseconds: 100, buckets: .main))
    }
}

// MARK: - Helpers

private extension OpenTelemetryMetricsServiceTests {
    func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// The spool directory is unique per pipeline: tests would otherwise share the real caches
    /// location with each other and with leftovers of earlier runs.
    func makePipeline(language: String? = "de", countryCode: String? = "de") -> CommonOpenTelemetryMetricsService.Pipeline {
        CommonOpenTelemetryMetricsService.makePipeline(
            configuration: makeConfiguration(language: language, countryCode: countryCode),
            storageURL: makeStorageURL()
        )
    }

    func makeService(spooled: Bool = true) -> CommonOpenTelemetryMetricsService {
        let service = CommonOpenTelemetryMetricsService()
        service.start(configuration: makeConfiguration(), storageURL: spooled ? makeStorageURL() : nil)
        return service
    }

    func makeConfiguration(language: String? = "de", countryCode: String? = "de") -> OTLPConfiguration {
        OTLPConfiguration(
            baseURL: URL(string: "https://otlp.example.com")!,
            apiKey: "test-key",
            serviceName: "tangem-ios",
            serviceVersion: "6.0",
            environment: "production",
            osName: "ios",
            osVersion: "18.0",
            language: language,
            countryCode: countryCode,
            session: makeSession()
        )
    }

    func makeStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "OTLPTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    func waitForRequest() async -> StubURLProtocol.Captured? {
        await waitForRequests(1).first
    }

    func waitForRequests(_ count: Int) async -> [StubURLProtocol.Captured] {
        for _ in 0 ..< 150 {
            let captured = StubURLProtocol.snapshot()
            if captured.count >= count { return captured }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return StubURLProtocol.snapshot()
    }

    func metrics(in captured: StubURLProtocol.Captured, named name: String) throws -> [Opentelemetry_Proto_Metrics_V1_Metric] {
        let body = try #require(captured.body)
        let deflated = Data(body.dropFirst(10).dropLast(8)) as NSData
        let request = try Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest(
            serializedBytes: deflated.decompressed(using: .zlib) as Data
        )

        return request.resourceMetrics
            .flatMap { $0.scopeMetrics }
            .flatMap { $0.metrics }
            .filter { $0.name == name }
    }
}

// MARK: - Stubbed transport

private extension OpenTelemetryMetricsServiceTests {
    final class StubURLProtocol: URLProtocol {
        struct Captured {
            let request: URLRequest
            let body: Data?
        }

        private static let captured = OSAllocatedUnfairLock(initialState: [Captured]())

        static func reset() {
            captured.withLock { $0 = [] }
        }

        static func snapshot() -> [Captured] {
            captured.withLock { $0 }
        }

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let capturedRequest = request
            let capturedBody = Self.readBody(from: capturedRequest)

            Self.captured.withLock { $0.append(Captured(request: capturedRequest, body: capturedBody)) }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

        /// The exporter streams the body, so `httpBody` is empty and the stream has to be drained.
        private static func readBody(from request: URLRequest) -> Data? {
            if let body = request.httpBody {
                return body
            }

            guard let stream = request.httpBodyStream else {
                return nil
            }

            stream.open()
            defer { stream.close() }

            var buffer = [UInt8](repeating: 0, count: 64 * 1024)
            var collected = Data()

            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                guard read > 0 else { break }
                collected.append(contentsOf: buffer.prefix(read))
            }

            return collected
        }
    }
}
