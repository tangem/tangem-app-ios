//
//  PresetsConfiguration.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct PresetsConfiguration: Decodable {
    public let maxResult: [PresetsGas]?
    public let lowestGas: [PresetsGas]?

    enum CodingKeys: String, CodingKey {
        case maxResult = "MAX_RESULT"
        case lowestGas = "LOWEST_GAS"
    }
}
