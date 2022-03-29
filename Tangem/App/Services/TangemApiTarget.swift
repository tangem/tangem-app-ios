//
//  TangemApiTarget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Moya

enum TangemApiTarget: TargetType {
    case rate(cryptoCurrencyCodes: [String], fiatCurrencyCode: String)
    case fiatMap
    
    var baseURL: URL {URL(string: "https://api.tangem-tech.com")!}
    
    var path: String {
        switch self {
        case .rate:
            return "/coins/prices"
        case .fiatMap:
            return "/coins/currencies"
        }
    }
    
    var method: Moya.Method { .get }
    
    var task: Task {
        switch self {
        case .rate(let cryptoCurrencyCodes, let fiatCurrencyCode):
            return .requestParameters(parameters: ["ids": cryptoCurrencyCodes.map { CurrencyCoinGeckoIdConverter.map($0) }.joined(separator: ","),
                                                   "currency": fiatCurrencyCode.lowercased()],
                                      encoding: URLEncoding.default)
        case .fiatMap:
           return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
}
