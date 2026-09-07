//
//  CollectiblesAPIServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemNetworkUtils
@testable import Tangem

@Suite("CollectiblesAPIService", .serialized)
struct CollectiblesAPIServiceTests {
    init() {
        CollectiblesStubURLProtocol.reset()
    }

    // MARK: - Lores

    @Test("Maps categories to lores and keeps the backend total")
    func mapsCategories() async throws {
        CollectiblesStubURLProtocol.responses = [
            Data(#"{"categories":[{"id":"pokemon","name":"Pokemon","machinesQuantity":7}],"totalMachinesQuantity":22}"#.utf8),
        ]

        let catalogue = try await makeSUT().load()

        let lore = try #require(catalogue.lores.first)
        #expect(lore.id == "pokemon")
        #expect(lore.title == "Pokemon")
        #expect(lore.packsCount == 7)
        #expect(catalogue.totalPacksCount == 22)
    }

    // MARK: - Packs

    @Test("Decodes a live-shaped machine and maps it: external id, short name, descaled price, fractional buyback rate")
    func mapsMachine() async throws {
        CollectiblesStubURLProtocol.responses = [
            Self.machinesPage(machines: [Self.machineJSON()], hasNext: false),
        ]

        let page = try await makeSUT().load(loreID: nil, query: "", cursor: nil)

        let pack = try #require(page.packs.first)
        #expect(pack.id == "pokemon_50")
        #expect(pack.name == "PKMN 50")
        #expect(pack.loreID == "pokemon")
        #expect(pack.price == 50)
        #expect(pack.currencyCode == "USD")
        #expect(pack.buybackRate == Decimal(string: "0.85"))
        #expect(pack.artworkURL == URL(string: "https://example.com/pack.png"))
    }

    @Test("Forwards the cursor and surfaces the page envelope")
    func forwardsCursorAndEnvelope() async throws {
        CollectiblesStubURLProtocol.responses = [
            Self.machinesPage(machines: [Self.machineJSON(externalId: "pokemon_250")], hasNext: true, cursor: "page-3"),
        ]

        let page = try await makeSUT().load(loreID: "pokemon", query: "", cursor: "page-2")

        #expect(page.packs.map(\.id) == ["pokemon_250"])
        #expect(page.hasNext == true)
        #expect(page.cursor == "page-3")
        #expect(Self.queryValue("cursor", of: CollectiblesStubURLProtocol.requests.first) == "page-2")
        #expect(Self.queryValue("categoryId", of: CollectiblesStubURLProtocol.requests.first) == "pokemon")
    }

    @Test("Sends a trimmed search query and omits a blank one", arguments: [
        ("  charizard ", "charizard"),
        ("   ", nil),
        ("", nil),
    ])
    func normalizesQuery(query: String, expected: String?) async throws {
        CollectiblesStubURLProtocol.responses = [
            Self.machinesPage(machines: [], hasNext: false),
        ]

        _ = try await makeSUT().load(loreID: nil, query: query, cursor: nil)

        #expect(Self.queryValue("search", of: CollectiblesStubURLProtocol.requests.first) == expected)
    }

    // MARK: - Headers

    @Test("Production header composition reaches the wire: session-id, platform and version")
    func productionHeadersReachTheWire() async throws {
        CollectiblesStubURLProtocol.responses = [
            Data(#"{"categories":[],"totalMachinesQuantity":0}"#.utf8),
        ]

        _ = try await makeSUT(headerValues: TangemProviderConfiguration.collectibles.headerValues).load()

        let headers = try #require(CollectiblesStubURLProtocol.requests.first?.allHTTPHeaderFields)
        #expect(headers["session-id"] == AppConstants.sessionId)
        #expect(headers["platform"] == "ios")
        #expect(headers["version"]?.isEmpty == false)
    }

    // MARK: - Errors

    @Test("Non-2xx response surfaces as .http with the status code and the raw body")
    func mapsHTTPFailure() async throws {
        CollectiblesStubURLProtocol.statusCode = 400
        CollectiblesStubURLProtocol.responses = [Data("machine out of stock".utf8)]

        do {
            _ = try await makeSUT().load()
            Issue.record("Expected .http to be thrown")
        } catch CollectiblesAPIService.Error.http(let statusCode, let body) {
            #expect(statusCode == 400)
            #expect(body == Data("machine out of stock".utf8))
        }
    }

    @Test("Transport failure surfaces as .connection")
    func mapsTransportFailure() async throws {
        CollectiblesStubURLProtocol.failure = URLError(.notConnectedToInternet)

        do {
            _ = try await makeSUT().load()
            Issue.record("Expected .connection to be thrown")
        } catch CollectiblesAPIService.Error.connection {}
    }
}

// MARK: - Helpers

private extension CollectiblesAPIServiceTests {
    func makeSUT(headerValues: [APIHeaderKeyInfo] = []) -> CollectiblesAPIService {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [CollectiblesStubURLProtocol.self]

        let configuration = TangemProviderConfiguration(
            logOptions: nil,
            urlSessionConfiguration: sessionConfiguration,
            headerValues: headerValues
        )

        return CollectiblesAPIService(provider: TangemProvider(configuration: configuration, additionalPlugins: [DeviceInfoPlugin()]))
    }

    static func queryValue(_ name: String, of request: URLRequest?) -> String? {
        request?.url
            .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?
            .first { $0.name == name }?
            .value
    }

    static func machinesPage(machines: [String], hasNext: Bool, cursor: String? = nil) -> Data {
        let cursorJSON = cursor.map { #""\#($0)""# } ?? "null"
        return Data(#"{"machines":[\#(machines.joined(separator: ","))],"hasNext":\#(hasNext),"cursor":\#(cursorJSON)}"#.utf8)
    }

    static func machineJSON(externalId: String = "pokemon_50") -> String {
        #"""
        {"id":"01a03802-433f-7ae5-a996-f981048a0a18","externalId":"\#(externalId)","name":"Elite Pokémon Gacha Pack",
        "shortName":"PKMN 50","price":5000,"instantBuybackPercent":85,"lowThreshold":50,
        "odds":{"common":80,"rare":4,"epic":1,"legendary":null},
        "tierRanges":{"common":{"start":30,"end":60},"rare":{"start":110,"end":250},"epic":{"start":250,"end":5001},"legendary":null},
        "stock":{"common":214,"rare":383,"epic":200,"legendary":null},
        "expectedValue":54.49,"image":"https://example.com/pack.png","categoryId":"pokemon","contains":"1",
        "fee":200,"feeAmount":100,"createdAt":"2026-08-25T08:21:07.518119Z","updatedAt":"2026-09-07T04:34:30.860676Z"}
        """#
    }
}

// MARK: - Stubs

private final class CollectiblesStubURLProtocol: URLProtocol {
    private struct State {
        var responses: [Data] = []
        var statusCode = 200
        var failure: (any Error)?
        var requests: [URLRequest] = []
    }

    private static let state = OSAllocatedUnfairLock(uncheckedState: State())

    static var responses: [Data] {
        get { state { $0.responses } }
        set { state { $0.responses = newValue } }
    }

    static var statusCode: Int {
        get { state { $0.statusCode } }
        set { state { $0.statusCode = newValue } }
    }

    static var failure: (any Error)? {
        get { state { $0.failure } }
        set { state { $0.failure = newValue } }
    }

    static var requests: [URLRequest] {
        state { $0.requests }
    }

    static func reset() {
        state { $0 = State() }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let (data, statusCode, failure) = Self.state { state -> (Data, Int, (any Error)?) in
            state.requests.append(request)
            let data = state.responses.isEmpty ? Data() : state.responses.removeFirst()
            return (data, state.statusCode, state.failure)
        }

        if let failure {
            client?.urlProtocol(self, didFailWithError: failure)
            return
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
