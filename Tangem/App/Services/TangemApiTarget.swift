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
        case rates(cryptoCurrencyIds: [String], fiatCurrencyCode: String)
        case baseCurrencies
        case checkContractAddress(contractAddress: String, networkId: String?)
    }
    
    let type: TangemApiTargetType
    let card: Card?
    
    var baseURL: URL {URL(string: "https://api.tangem-tech.com")!}
    
    var path: String {
        switch type {
        case .rates:
            return "/coins/prices"
        case .baseCurrencies:
            return "/coins/currencies"
        case .checkContractAddress:
            return "/coins/check-address"
        }
    }
    
    var method: Moya.Method { .get }
    
    var task: Task {
        switch type {
        case .rates(let cryptoCurrencyIds, let fiatCurrencyCode):
            return .requestParameters(parameters: ["ids": cryptoCurrencyIds.joined(separator: ","),
                                                   "currency": fiatCurrencyCode.lowercased()],
                                      encoding: URLEncoding.default)
        case .baseCurrencies:
            return .requestPlain
        case .checkContractAddress(let contractAddress, let networkId):
            var parameters: [String: Any] = ["contractAddress": contractAddress]
            if let networkId = networkId {
                parameters["networkId"] = networkId
            }
            return .requestParameters(parameters: parameters,
                                      encoding: URLEncoding.default)
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
