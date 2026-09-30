//
//  TonConnectDeepLinkParserTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectDeepLinkParserTests {
    private let parser = TonConnectDeepLinkParser()
    private static let clientIDHex = String(repeating: "ab", count: 32)
    private static let connectRequestJSON = #"{"manifestUrl":"https://app.example.com/tonconnect-manifest.json","items":[{"name":"ton_addr"},{"name":"ton_proof","payload":"nonce-123"}]}"#

    private func makeURL(scheme: String = "tc", host: String = "", path: String = "", query: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }

    @Test
    func parsesUnifiedLinkWithAllParameters() throws {
        let url = makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": Self.connectRequestJSON, "ret": "back", "trace_id": "019a2a92-a884-7cfc-b1bc-caab18644b6f"])

        let link = try parser.parse(url)

        #expect(parser.isUnifiedLink(url))
        #expect(link.protocolVersion == 2)
        #expect(link.dAppClientID.hexString == Self.clientIDHex)
        #expect(link.returnStrategy == .back)
        #expect(link.traceID == "019a2a92-a884-7cfc-b1bc-caab18644b6f")

        let request = try #require(link.connectRequest)
        #expect(request.manifestUrl.absoluteString == "https://app.example.com/tonconnect-manifest.json")
        #expect(request.items == [.tonAddress(network: nil), .tonProof(payload: "nonce-123")])
        #expect(request.proofPayload == "nonce-123")
    }

    @Test
    func parsesUniversalLinkWithSameParameters() throws {
        let url = makeURL(scheme: "https", host: "app.tangem.com", path: "/ton-connect", query: ["v": "2", "id": Self.clientIDHex, "r": Self.connectRequestJSON])

        let link = try parser.parse(url)

        #expect(!parser.isUnifiedLink(url))
        #expect(link.connectRequest != nil)
        #expect(link.returnStrategy == .back, "ret defaults to back")
    }

    @Test
    func parsesReturnStrategies() throws {
        let none = try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": Self.connectRequestJSON, "ret": "none"]))
        #expect(none.returnStrategy == .none)

        let custom = try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": Self.connectRequestJSON, "ret": "https://back.example.com/done"]))
        #expect(custom.returnStrategy == .url(URL(string: "https://back.example.com/done")!))

        let garbage = try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": Self.connectRequestJSON, "ret": "not a url"]))
        #expect(garbage.returnStrategy == .back)
    }

    @Test
    func parsesEmptyReturnOnlyLink() throws {
        let link = try parser.parse(makeURL(query: ["id": Self.clientIDHex, "ret": "none"]))

        #expect(link.connectRequest == nil)
        #expect(link.returnStrategy == .none)
        #expect(link.dAppClientID.hexString == Self.clientIDHex)
    }

    @Test
    func preservesTonAddressNetworkAndUnknownItems() throws {
        let json = #"{"manifestUrl":"https://d.app","items":[{"name":"ton_addr","network":"-3"},{"name":"ton_future","extra":1}]}"#
        let link = try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": json]))

        #expect(link.connectRequest?.items == [.tonAddress(network: .testnet), .unsupported(name: "ton_future")])
    }

    @Test(arguments: [nil, "1", "3", "two"])
    func rejectsUnsupportedVersion(version: String?) {
        var query = ["id": Self.clientIDHex, "r": Self.connectRequestJSON]
        if let version { query["v"] = version }

        #expect(throws: TonConnectError.unsupportedProtocolVersion(version)) {
            try parser.parse(makeURL(query: query))
        }
    }

    @Test(arguments: ["", "abcd", String(repeating: "zz", count: 32), String(repeating: "ab", count: 33), "0x" + String(repeating: "ab", count: 31)])
    func rejectsInvalidClientID(id: String) {
        #expect(throws: TonConnectError.invalidClientID) {
            try parser.parse(makeURL(query: ["v": "2", "id": id, "r": Self.connectRequestJSON]))
        }
    }

    @Test
    func rejectsMissingClientID() {
        #expect(throws: TonConnectError.malformedConnectRequest("missing id")) {
            try parser.parse(makeURL(query: ["v": "2", "r": Self.connectRequestJSON]))
        }
    }

    @Test
    func rejectsMalformedConnectRequest() {
        #expect(throws: TonConnectError.malformedConnectRequest("r is not a valid ConnectRequest")) {
            try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": "{not json"]))
        }
    }

    @Test
    func rejectsConnectRequestWithoutTonAddressItem() {
        let json = #"{"manifestUrl":"https://d.app/m.json","items":[{"name":"ton_proof","payload":"x"}]}"#

        #expect(throws: TonConnectError.malformedConnectRequest("ton_addr item is required")) {
            try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": json]))
        }
    }

    @Test
    func rejectsNonHTTPSManifestURL() {
        let json = #"{"manifestUrl":"http://d.app/m.json","items":[{"name":"ton_addr"}]}"#

        #expect(throws: TonConnectError.malformedConnectRequest("manifestUrl must use https")) {
            try parser.parse(makeURL(query: ["v": "2", "id": Self.clientIDHex, "r": json]))
        }
    }
}
