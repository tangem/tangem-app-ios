//
//  CollectiblesDTO+PurchaseTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension CollectiblesDTO {
    struct PurchaseTransaction: Decodable {
        let txID: String
        let status: String
        let nftWon: NftWon?

        private enum CodingKeys: String, CodingKey {
            case txID = "txId"
            case status
            case nftWon
        }
    }

    struct NftWon: Decodable {
        let nftAddress: String?
        let gradingCompany: String?
        let theGrade: String?
        let gradingID: String?
        let imageFront: String?
        let imageBack: String?
        let rarity: String?
        let year: String?
        let set: String?
        let serialNumber: String?
        /// Insured value in cents.
        let insuredValue: Decimal?
    }
}
