//
//  CommonExpressAPIServiceErrorDescriptionTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemExpress

@Suite("CommonExpressAPIService — the backend description of an Express error")
struct CommonExpressAPIServiceErrorDescriptionTests {
    @Test("With the toggle on, the backend description is dropped")
    func descriptionDroppedWithToggle() async {
        let error = await requestError(isHideRejectedSwapProvidersEnabled: true)

        #expect(error?.code == 2264)
        #expect(error?.errorDescription == "Error. Code: 2264")
    }

    @Test("With the toggle off, the backend description is kept")
    func descriptionKeptWithoutToggle() async {
        let error = await requestError(isHideRejectedSwapProvidersEnabled: false)

        #expect(error?.errorDescription == "Core: address is banned by AML. Code: 2264")
    }
}

// MARK: - Helpers

private extension CommonExpressAPIServiceErrorDescriptionTests {
    func requestError(isHideRejectedSwapProvidersEnabled: Bool) async -> ExpressAPIError? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ExpressErrorURLProtocol.self]

        let provider = TangemExpressFactory().makeExpressAPIProvider(
            credential: ExpressAPICredential(apiKey: "", userId: "", sessionId: "", refcode: nil),
            configuration: configuration,
            expressAPIType: .production,
            exchangeDataDecoder: StubExchangeDataDecoder(),
            featureFlags: ExpressFeatureFlags(
                isSwapBestRateDefaultProviderEnabled: false,
                isHideRejectedSwapProvidersEnabled: isHideRejectedSwapProvidersEnabled
            )
        )

        do {
            _ = try await provider.providers(branches: [.swap])
            return nil
        } catch {
            return error as? ExpressAPIError
        }
    }
}

private final class ExpressErrorURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = Data(#"{"error":{"code":2264,"description":"Core: address is banned by AML"}}"#.utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct StubExchangeDataDecoder: ExpressExchangeDataDecoder {
    func decode<T: Decodable>(txDetailsJson: String, signature: String) throws -> T {
        fatalError("Not used in tests")
    }
}
