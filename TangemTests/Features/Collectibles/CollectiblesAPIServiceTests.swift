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

    // MARK: - Machine detail

    @Test("Maps the machine detail: descaled money, fractional odds, tiers in rarity order with absent ones dropped")
    func mapsMachineDetail() async throws {
        CollectiblesStubURLProtocol.responses = [Data(Self.machineJSON().utf8)]

        let machine = try await makeSUT().load(id: "pokemon_50")

        #expect(machine.name == "PKMN 50")
        #expect(machine.price == 50)
        #expect(machine.cardsPerPack == 1)
        #expect(machine.buybackRate == Decimal(string: "0.85"))
        #expect(machine.expectedValue == Decimal(string: "54.5"))

        // The fixture carries no uncommon key and a null legendary: both mean the machine has no such tier.
        #expect(machine.tiers.map(\.tier) == [.common, .rare, .epic])

        let common = try #require(machine.tiers.first)
        #expect(common.odds == Decimal(string: "0.8"))
        #expect(common.valueRange == Decimal(30) ... Decimal(60))

        let requestPath = try #require(CollectiblesStubURLProtocol.requests.first?.url?.path)
        #expect(requestPath.hasSuffix("api/v1/machine/pokemon_50"))
    }

    @Test("An inverted value range is dropped and the tier keeps its odds")
    func dropsInvertedValueRange() async throws {
        let json = Self.machineJSON(commonRange: #"{"start":60,"end":30}"#)
        CollectiblesStubURLProtocol.responses = [Data(json.utf8)]

        let machine = try await makeSUT().load(id: "pokemon_50")

        let common = try #require(machine.tiers.first)
        #expect(common.tier == .common)
        #expect(common.valueRange == nil)
        #expect(common.odds == Decimal(string: "0.8"))
    }

    // MARK: - Pack opening

    @Test("generateTx: posts the body with the user-id header and decodes the unsigned transaction")
    func generatesTransaction() async throws {
        CollectiblesStubURLProtocol.responses = [Data(#"{"id":"tx-1","txData":"AAEC"}"#.utf8)]

        let request = CollectiblesDTO.GenerateTxRequest(fromAddress: "owner", collectibleType: "pokemon_50", toAddress: "cold")
        let response = try await makeSUT().generatePackTransaction(request, userWalletID: "wallet-1")

        #expect(response.id == "tx-1")
        #expect(response.txData == "AAEC")

        let sent = try #require(CollectiblesStubURLProtocol.requests.first)
        let sentPath = try #require(sent.url?.path)
        #expect(sent.httpMethod == "POST")
        #expect(sentPath.hasSuffix("api/v1/collectible/generateTx"))
        #expect(sent.value(forHTTPHeaderField: "user-id") == "wallet-1")

        let body = try Self.jsonBody(CollectiblesStubURLProtocol.bodies.first)
        #expect(body["fromAddress"] as? String == "owner")
        #expect(body["collectibleType"] as? String == "pokemon_50")
        #expect(body["toAddress"] as? String == "cold")
        #expect(body["turboMode"] == nil)
    }

    @Test("submitTx: posts the signed transaction with the user-id header and decodes the id")
    func submitsTransaction() async throws {
        CollectiblesStubURLProtocol.responses = [Data(#"{"id":"tx-1"}"#.utf8)]

        let response = try await makeSUT().submitPackTransaction(.init(signedTxData: "c2lnbmVk"), userWalletID: "wallet-1")

        #expect(response.id == "tx-1")

        let sent = try #require(CollectiblesStubURLProtocol.requests.first)
        let sentPath = try #require(sent.url?.path)
        #expect(sent.httpMethod == "POST")
        #expect(sentPath.hasSuffix("api/v1/collectible/submitTx"))
        #expect(sent.value(forHTTPHeaderField: "user-id") == "wallet-1")

        let body = try Self.jsonBody(CollectiblesStubURLProtocol.bodies.first)
        #expect(body["signedTxData"] as? String == "c2lnbmVk")
        #expect(body.count == 1)
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

    static func jsonBody(_ data: Data?) throws -> [String: Any] {
        guard let data, let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.notJSONBody
        }
        return body
    }

    enum TestError: Error { case notJSONBody }

    static func machinesPage(machines: [String], hasNext: Bool, cursor: String? = nil) -> Data {
        let cursorJSON = cursor.map { #""\#($0)""# } ?? "null"
        return Data(#"{"machines":[\#(machines.joined(separator: ","))],"hasNext":\#(hasNext),"cursor":\#(cursorJSON)}"#.utf8)
    }

    static func machineJSON(
        externalId: String = "pokemon_50",
        commonRange: String = #"{"start":30,"end":60}"#
    ) -> String {
        #"""
        {"id":"01a03802-433f-7ae5-a996-f981048a0a18","externalId":"\#(externalId)","name":"Elite Pokémon Gacha Pack",
        "shortName":"PKMN 50","price":5000,"instantBuybackPercent":85,"lowThreshold":50,
        "odds":{"common":80,"rare":4,"epic":1,"legendary":null},
        "tierRanges":{"common":\#(commonRange),"rare":{"start":110,"end":250},"epic":{"start":250,"end":5001},"legendary":null},
        "stock":{"common":214,"rare":383,"epic":200,"legendary":null},
        "expectedValue":54.5,"image":"https://example.com/pack.png","categoryId":"pokemon","contains":1,
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
        var bodies: [Data] = []
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

    static var bodies: [Data] {
        state { $0.bodies }
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
        let body = Self.body(of: request)
        let (data, statusCode, failure) = Self.state { state -> (Data, Int, (any Error)?) in
            state.requests.append(request)
            state.bodies.append(body)
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

    private static func body(of request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return Data()
        }

        stream.open()
        defer { stream.close() }

        var body = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 1024)
            guard count > 0 else { break }
            body.append(buffer, count: count)
        }

        return body
    }
}
