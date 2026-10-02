//
//  CollectiblesAPITargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import Tangem

@Suite("CollectiblesAPITarget")
final class CollectiblesAPITargetTests {
    @Test("Paths")
    func paths() {
        #expect(makeTarget(.categories).path == "api/v1/machine/categories")
        #expect(makeTarget(.machines(.init())).path == "api/v1/machine/machines")
        #expect(makeTarget(.machine(externalID: "pokemon_50")).path == "api/v1/machine/pokemon_50")
    }

    @Test("Catalogue is read with GET")
    func methods() {
        #expect(makeTarget(.categories).method == .get)
        #expect(makeTarget(.machines(.init())).method == .get)
        #expect(makeTarget(.machine(externalID: "pokemon_50")).method == .get)
    }

    @Test("Only the calls the backend scopes to a wallet carry the user-id header")
    func userIDHeader() {
        #expect(makeTarget(.categories).headers == nil)
        #expect(makeTarget(.machines(.init())).headers == nil)
        #expect(makeTarget(.machine(externalID: "pokemon_50")).headers == nil)
        #expect(makeTarget(.machineNfts(externalID: "pokemon_50", .init(page: 1, limit: 50), userWalletID: "wallet-3")).headers == ["user-id": "wallet-3"])
    }

    @Test("machines: empty request sends no query")
    func machinesEmptyParameters() throws {
        let parameters = try queryParameters(makeTarget(.machines(.init())).task)

        #expect(parameters.isEmpty)
    }

    @Test("machines: only non-nil fields become query items")
    func machinesPartialParameters() throws {
        let request = CollectiblesDTO.MachinesRequest(categoryID: "cat-1", limit: 20)

        let parameters = try queryParameters(makeTarget(.machines(request)).task)

        #expect(parameters["categoryId"] as? String == "cat-1")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["search"] == nil)
        #expect(parameters["cursor"] == nil)
    }

    @Test("machines: full request sends all four query items")
    func machinesFullParameters() throws {
        let request = CollectiblesDTO.MachinesRequest(categoryID: "cat-1", search: "pikachu", limit: 20, cursor: "next")

        let parameters = try queryParameters(makeTarget(.machines(request)).task)

        #expect(parameters["categoryId"] as? String == "cat-1")
        #expect(parameters["search"] as? String == "pikachu")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["cursor"] as? String == "next")
        #expect(parameters.count == 4)
    }
}

// MARK: - Helpers

private extension CollectiblesAPITargetTests {
    func makeTarget(_ target: CollectiblesAPITarget.Target) -> CollectiblesAPITarget {
        CollectiblesAPITarget(baseURL: URL(string: "https://example.com")!, target: target)
    }

    func queryParameters(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestParameters(let parameters, _) = task else {
            throw TestError.notRequestParameters
        }
        return parameters
    }

    func jsonBody(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestJSONEncodable(let encodable) = task else {
            throw TestError.notJSONEncodable
        }

        let data = try JSONEncoder().encode(encodable)

        guard let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.notJSONObject
        }
        return body
    }

    enum TestError: Error { case notRequestParameters, notJSONEncodable, notJSONObject }
}
