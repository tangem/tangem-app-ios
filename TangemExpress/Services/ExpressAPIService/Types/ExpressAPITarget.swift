//
//  ExpressAPITarget.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Moya
import TangemFoundation

struct ExpressAPITarget: Moya.TargetType {
    let expressAPIType: ExpressAPIType
    let target: Target

    enum Target {
        case assets(request: ExpressDTO.Assets.Request)
        case pairs(request: ExpressDTO.Pairs.Request)
        case providers
        case exchangeQuote(request: ExpressDTO.ExchangeQuote.Request)
        case exchangeData(request: ExpressDTO.ExchangeData.Request)
        case exchangeStatus(request: ExpressDTO.ExchangeStatus.Request)
    }

    var baseURL: URL {
        switch expressAPIType {
        case .develop:
            return URL(string: "https://express.tangem.org/v1/")!
        case .production:
            return URL(string: "https://express.tangem.com/v1/")!
        }
    }

    var path: String {
        switch target {
        case .assets: return "assets"
        case .pairs: return "pairs"
        case .providers: return "providers"
        case .exchangeQuote: return "exchange-quote"
        case .exchangeData: return "exchange-data"
        case .exchangeStatus: return "exchange-status"
        }
    }

    var method: Moya.Method {
        switch target {
        case .assets, .pairs: return .post
        case .providers, .exchangeQuote, .exchangeData, .exchangeStatus: return .get
        }
    }

    var task: Moya.Task {
        switch target {
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
        case .exchangeStatus(let request):
            return .requestParameters(request)
        }
    }

    var headers: [String: String]? { nil }
}
