//
//  ExpressAPITarget.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya

enum ExpressAPITarget: Moya.TargetType {
    case assets(request: ExpressDTO.Assets.Request)
    case pairs(request: ExpressDTO.Pairs.Request)
    case providers
    case exchangeQuote(request: ExpressDTO.ExchangeQuote.Request)
    case exchangeData(request: ExpressDTO.ExchangeData.Request)
    case exchangeResults(request: ExpressDTO.ExchangeResult.Request)

    var baseURL: URL {
        URL(string: "https://express.tangem.org/v1/")!
    }

    var path: String {
        switch self {
        case .assets: return "assets"
        case .pairs: return "pairs"
        case .providers: return "providers"
        case .exchangeQuote: return "exchange-quote"
        case .exchangeData: return "exchange-data"
        case .exchangeResults: return "exchange-results"
        }
    }

    var method: Moya.Method {
        switch self {
        case .assets, .pairs: return .post
        case .providers, .exchangeQuote, .exchangeData, .exchangeResults: return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .assets(let request):
            return .requestJSONEncodable(request)
        case .pairs(let request):
            return .requestJSONEncodable(request)
        case .providers:
            return .requestPlain
        case .exchangeQuote(let request):
            return .requestParameters(request)
        case .exchangeData(let request):
            return .requestParameters(request)
        case .exchangeResults(let request):
            return .requestParameters(request)
        }
    }

    var headers: [String: String]? { nil }
}
