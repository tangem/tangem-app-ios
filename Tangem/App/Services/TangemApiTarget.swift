//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya
import TangemSdk

struct TangemApiTarget: TargetType {
    enum TangemApiTargetType {
        case rates(coinIds: [String], currencyId: String)
        case currencies
        case coins(contractAddress: String?, networkId: String?)
    }
    
    let type: TangemApiTargetType
    let card: Card?

    var baseURL: URL {URL(string: "https://api.tangem-tech.com/v1")!}
    
    var path: String {
        switch type {
        case .rates:
            return "/rates"
        case .currencies:
            return "/currencies"
        case .coins:
            return "/coins"
        }
    }
    
    var method: Moya.Method { .get }
    
    var task: Task {
        switch type {
        case .rates(let coinIds, let currencyId):
            return .requestParameters(parameters: ["coinIds": coinIds.joined(separator: ","),
                                                   "currencyId": currencyId.lowercased()],
                                      encoding: URLEncoding.default)
        case .currencies:
            return .requestPlain
        case .coins(let contractAddress, let networkId):
            var parameters: [String: Any] = [:]
            
            if let contractAddress = contractAddress {
                parameters["contractAddress"] = contractAddress
            }

            if let networkId = networkId {
                parameters["networkId"] = networkId
            }
            
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        guard let card = card else {
            return nil
        }

        return [
            "card_id": card.cardId,
            "card_public_key": card.cardPublicKey.hexString,
        ]
    }
}
