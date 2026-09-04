//
//  CollectiblesAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CollectiblesAPIService {
    func categories() async throws -> CollectiblesDTO.MachineCategoriesResponse
    func machines(request: CollectiblesMachinesRequest) async throws -> CollectiblesDTO.MachinesResponse
    /// Machine by its external id (e.g. `pokemon_50`), not by the internal `id`.
    func machine(externalID: String) async throws -> CollectiblesDTO.Machine
}
