//
//  CardNetworkDetails.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

struct CardNetworkArtwork: Codable {

    var date: String
    var hash: String
    var artworkId: String

    enum CodingKeys: String, CodingKey {
        case date
        case hash
        case artworkId = "id"
    }

}

struct CardDetailsSubstitution: Codable {
    
    struct CardSubstitutionDataModel: Codable {
        
        let tokenSymbol: String?
        let tokenContractAddress: String?
        let tokenDecimal: Int?
        
        enum CodingKeys: String, CodingKey {
            case tokenSymbol = "token_symbol"
            case tokenContractAddress = "token_contract_address"
            case tokenDecimal = "token_decimal"
        }
        
    }
    
    var dataString: String?
    var signature: String?
    
    enum CodingKeys: String, CodingKey {
        case dataString = "data"
        case signature
    }
    
    var substutionData: CardSubstitutionDataModel? {
        var model: CardSubstitutionDataModel?
        do {
            let data = dataString?.data(using: .utf8)
            model = try JSONDecoder().decode(CardSubstitutionDataModel.self, from: data!)
        } catch {
            print(error)
        }
        
        return model
    }
}

struct CardNetworkDetails: Codable {

    var cardId: String
    var artwork: CardNetworkArtwork?
    var substitution: CardDetailsSubstitution?
    var batch: String?
    var isValid: Bool

    enum CodingKeys: String, CodingKey {
        case cardId = "CID"
        case artwork
        case batch
        case isValid = "passed"
        case substitution
    }
    
}
