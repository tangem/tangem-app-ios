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

    enum TestError: Error { case notRequestParameters }
}
