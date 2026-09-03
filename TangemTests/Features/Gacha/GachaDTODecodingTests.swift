//
//  GachaDTODecodingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("GachaDTO")
final class GachaDTODecodingTests {
    // MARK: - Machine

    @Test("Decodes a machine with every field populated")
    func decodesFullMachine() throws {
        let machine: GachaDTO.Machine = try decode(makeMachineJSON())

        #expect(machine.id == "m-1")
        #expect(machine.externalId == "pokemon_50")
        #expect(machine.name == "Pokemon 50")
        #expect(machine.shortName == "PKM50")
        #expect(machine.price == Decimal(string: "49.99"))
        #expect(machine.fee == 2)
        #expect(machine.feeAmount == 1)
        #expect(machine.contains == 5)
        #expect(machine.instantBuybackPercent == 80)
        #expect(machine.lowThreshold == 10)
        #expect(machine.odds.common == 70)
        #expect(machine.odds.epic == 2)
        #expect(machine.tierRanges.rare.start == 30)
        #expect(machine.tierRanges.rare.end == 99)
        #expect(machine.stock.uncommon == 40)
        #expect(machine.expectedValue == 42)
        #expect(machine.image == "https://example.com/pack.png")
        #expect(machine.categoryId == "cat-1")
    }

    @Test("Decodes a machine carrying no optional fields")
    func decodesMachineWithoutOptionals() throws {
        let machine: GachaDTO.Machine = try decode(makeMachineJSON(contains: "null", image: "null"))

        #expect(machine.contains == nil)
        #expect(machine.image == nil)
    }

    // MARK: - Machines Page

    @Test("Decodes a machines page with pagination fields")
    func decodesMachinesPage() throws {
        let json = """
        {
            "machines": [\(makeMachineJSON())],
            "hasNext": true,
            "cursor": "next-cursor"
        }
        """

        let page: GachaDTO.MachinesResponse = try decode(json)

        #expect(page.machines.count == 1)
        #expect(page.hasNext)
        #expect(page.cursor == "next-cursor")
    }

    @Test("Decodes the last machines page carrying no cursor")
    func decodesLastMachinesPage() throws {
        let json = """
        {
            "machines": [],
            "hasNext": false,
            "cursor": null
        }
        """

        let page: GachaDTO.MachinesResponse = try decode(json)

        #expect(page.machines.isEmpty)
        #expect(!page.hasNext)
        #expect(page.cursor == nil)
    }

    // MARK: - Categories

    @Test("Decodes categories with machine counters")
    func decodesCategories() throws {
        let json = """
        {
            "categories": [
                { "id": "cat-1", "name": "Pokemon", "machinesQuantity": 12 },
                { "id": "cat-2", "name": "One Piece", "machinesQuantity": 8 }
            ],
            "totalMachinesQuantity": 20
        }
        """

        let response: GachaDTO.MachineCategoriesResponse = try decode(json)

        #expect(response.categories.map(\.id) == ["cat-1", "cat-2"])
        #expect(response.categories.first?.name == "Pokemon")
        #expect(response.categories.first?.machinesQuantity == 12)
        #expect(response.totalMachinesQuantity == 20)
    }
}

// MARK: - Helpers

private extension GachaDTODecodingTests {
    func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    func makeMachineJSON(contains: String = "5", image: String = "\"https://example.com/pack.png\"") -> String {
        """
        {
            "id": "m-1",
            "externalId": "pokemon_50",
            "name": "Pokemon 50",
            "shortName": "PKM50",
            "price": 49.99,
            "fee": 2,
            "feeAmount": 1,
            "contains": \(contains),
            "instantBuybackPercent": 80,
            "lowThreshold": 10,
            "odds": { "common": 70, "uncommon": 20, "rare": 8, "epic": 2 },
            "tierRanges": {
                "common": { "start": 1, "end": 9 },
                "uncommon": { "start": 10, "end": 29 },
                "rare": { "start": 30, "end": 99 },
                "epic": { "start": 100, "end": 500 }
            },
            "stock": { "common": 120, "uncommon": 40, "rare": 12, "epic": 3 },
            "expectedValue": 42,
            "image": \(image),
            "categoryId": "cat-1",
            "createdAt": "2026-08-01T00:00:00Z",
            "updatedAt": "2026-08-15T00:00:00Z"
        }
        """
    }
}
