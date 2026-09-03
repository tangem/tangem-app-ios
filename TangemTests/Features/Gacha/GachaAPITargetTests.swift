//
//  GachaAPITargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import Tangem

@Suite("GachaAPITarget")
final class GachaAPITargetTests {
    @Test("Paths")
    func paths() {
        #expect(makeTarget(.categories).path == "api/v1/machine/categories")
        #expect(makeTarget(.machines(.init())).path == "api/v1/machine/machines")
        #expect(makeTarget(.machine(externalID: "pokemon_50")).path == "api/v1/machine/pokemon_50")
    }

    @Test("machines: empty request sends no query")
    func machinesEmptyParameters() {
        #expect(isRequestPlain(makeTarget(.machines(.init())).task))
    }

    @Test("machines: only non-nil fields become query items")
    func machinesPartialParameters() throws {
        let request = GachaMachinesRequest(categoryID: "cat-1", limit: 20)

        let parameters = try queryParameters(makeTarget(.machines(request)).task)

        #expect(parameters["categoryId"] as? String == "cat-1")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["search"] == nil)
        #expect(parameters["cursor"] == nil)
    }

    @Test("machines: full request sends all four query items")
    func machinesFullParameters() throws {
        let request = GachaMachinesRequest(categoryID: "cat-1", search: "pikachu", limit: 20, cursor: "next")

        let parameters = try queryParameters(makeTarget(.machines(request)).task)

        #expect(parameters["categoryId"] as? String == "cat-1")
        #expect(parameters["search"] as? String == "pikachu")
        #expect(parameters["limit"] as? Int == 20)
        #expect(parameters["cursor"] as? String == "next")
        #expect(parameters.count == 4)
    }
}

// MARK: - Helpers

private extension GachaAPITargetTests {
    func makeTarget(_ target: GachaAPITarget.Target) -> GachaAPITarget {
        GachaAPITarget(baseURL: URL(string: "https://example.com")!, target: target)
    }

    func isRequestPlain(_ task: Moya.Task) -> Bool {
        if case .requestPlain = task { return true }
        return false
    }

    func queryParameters(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestParameters(let parameters, _) = task else {
            throw TestError.notRequestParameters
        }
        return parameters
    }

    enum TestError: Error { case notRequestParameters }
}
