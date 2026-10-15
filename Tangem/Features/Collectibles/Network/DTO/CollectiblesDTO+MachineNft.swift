//
//  CollectiblesDTO+MachineNft.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct MachineNft: Decodable {
        let id: String
        let name: String
        let description: String?
        let rarity: String?
        /// The grader that slabbed the card, absent for an ungraded one.
        let gradingCompany: String?
        let gradeNum: String?
        let image: String?
        /// Appraised value in cents.
        let insuredValue: Decimal?

        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case description
            case rarity
            case gradingCompany
            case gradeNum
            case image
            case insuredValue = "insured_value"
        }
    }
}
