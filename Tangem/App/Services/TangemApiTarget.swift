//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya

enum TangemApiTarget: TargetType {
    case rates(cryptoCurrencyCodes: [String], fiatCurrencyCode: String)
    case baseCurrencies
    
    var baseURL: URL {URL(string: "https://api.tangem-tech.com")!}
    
    var path: String {
        switch self {
        case .rates:
            return "/coins/prices"
        case .baseCurrencies:
            return "/coins/currencies"
        }
    }
    
    var method: Moya.Method { .get }
    
    var task: Task {
        switch self {
        case .rates(let cryptoCurrencyCodes, let fiatCurrencyCode):
            return .requestParameters(parameters: ["ids": cryptoCurrencyCodes.map { CurrencyCoinGeckoIdConverter.map($0) }.joined(separator: ","),
                                                   "currency": fiatCurrencyCode.lowercased()],
                                      encoding: URLEncoding.default)
        case .baseCurrencies:
           return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        // [REDACTED_TODO_COMMENT]
        return nil
    }
}
