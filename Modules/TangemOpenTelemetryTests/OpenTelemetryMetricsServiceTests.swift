//
//  OpenTelemetryMetricsServiceTests.swift
//  TangemOpenTelemetryTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
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
            session: makeSession()
        )

        #expect(configuration.metricsURL.absoluteString == "https://otlp.example.com/v1/metrics")
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
    func makePipeline() -> CommonOpenTelemetryMetricsService.Pipeline {
        let configuration = OTLPConfiguration(
            baseURL: URL(string: "https://otlp.example.com")!,
            apiKey: "test-key",
            serviceName: "tangem-ios",
            serviceVersion: "6.0",
            environment: "production",
            session: makeSession()
        )

        let storageURL = FileManager.default.temporaryDirectory
            .appending(path: "OTLPTests-\(UUID().uuidString)", directoryHint: .isDirectory)

        return CommonOpenTelemetryMetricsService.makePipeline(configuration: configuration, storageURL: storageURL)
    }

    func waitForRequest() async -> StubURLProtocol.Captured? {
        for _ in 0 ..< 150 {
            if let first = StubURLProtocol.snapshot().first { return first }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return nil
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
