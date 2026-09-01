//
//  GachaAPIService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol GachaAPIService {
    func categories() async throws -> GachaDTO.MachineCategoriesResponse
    func machines(request: GachaMachinesRequest) async throws -> GachaDTO.MachinesResponse
    /// Machine by its external id (e.g. `pokemon_50`), not by the internal `id`.
    func machine(externalID: String) async throws -> GachaDTO.Machine
}
