//
//  ExpressAPITarget.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

struct ExpressAPITarget: Moya.TargetType {
    let expressAPIType: ExpressAPIType
    let target: Target

    enum Target {
        case assets(request: ExpressDTO.Swap.Assets.Request)
        case pairs(request: ExpressDTO.Swap.Pairs.Request)
        case providers
        case exchangeQuote(request: ExpressDTO.Swap.ExchangeQuote.Request)
        case exchangeData(request: ExpressDTO.Swap.ExchangeData.Request)
        case exchangeStatus(request: ExpressDTO.Swap.ExchangeStatus.Request)
        case exchangeSent(request: ExpressDTO.Swap.ExchangeSent.Request)
        case exchangeHistory(request: ExpressDTO.Swap.History.Request)
        case exchangeHistoryDelta(request: ExpressDTO.Swap.HistoryDelta.Request)

        case onrampCurrencies
        case onrampCountries
        case onrampCountryByIP
        case onrampPaymentMethods
        case onrampPairs(request: ExpressDTO.Onramp.Pairs.Request)
        case onrampQuote(request: ExpressDTO.Onramp.Quote.Request)
        case onrampData(request: ExpressDTO.Onramp.Data.Request)
        case onrampNativePaymentData(request: ExpressDTO.Onramp.NativePaymentData.Request)
        case onrampStatus(request: ExpressDTO.Onramp.Status.Request)
        case onrampHistory(request: ExpressDTO.Onramp.History.Request)
        case onrampHistoryDelta(request: ExpressDTO.Onramp.HistoryDelta.Request)
    }

    var baseURL: URL {
        switch expressAPIType {
        case .develop:
            return URL(string: "https://express.tangem.org/v1/")!
        case .develop2:
            return URL(string: "https://express2.tests-d.com/v1/")!
        case .develop3:
            return URL(string: "https://express3.tests-d.com/v1/")!
        case .production:
            return URL(string: "https://express.tangem.com/v1/")!
        case .stage:
            return URL(string: "https://express-stage.tangem.com/v1/")!
        case .stage2:
            return URL(string: "https://express.tests-s1.com/v1/")!
        case .stage3:
            return URL(string: "https://express.tests-s2.com/v1/")!
        case .mock:
            return URL(string: "\(WireMockEnvironment.baseURL)/v1/")!
        }
    }

    var path: String {
        switch target {
        case .assets: "assets"
        case .pairs: "pairs"
        case .providers: "providers"
        case .exchangeQuote: "exchange-quote"
        case .exchangeData: "exchange-data"
        case .exchangeStatus: "exchange-status"
        case .exchangeSent: "exchange-sent"
        case .exchangeHistory: "history/exchange"
        case .exchangeHistoryDelta: "history/delta/exchange"
        case .onrampCurrencies: "currencies"
        case .onrampCountries: "countries"
        case .onrampCountryByIP: "country-by-ip"
        case .onrampPaymentMethods: "payment-methods"
        case .onrampPairs: "onramp-pairs"
        case .onrampQuote: "onramp-quote"
        case .onrampData: "onramp-data"
        // Same endpoint as .onrampData but uses POST method with JSON body for native payment flow
        case .onrampNativePaymentData: "onramp-data"
        case .onrampStatus: "onramp-status"
        case .onrampHistory: "history/onramp"
        case .onrampHistoryDelta: "history/delta/onramp"
        }
    }

    var method: Moya.Method {
        switch target {
        case .assets,
             .pairs,
             .exchangeSent,
             .onrampPairs,
             .onrampNativePaymentData:
            return .post
        case .providers,
             .exchangeQuote,
             .exchangeData,
             .exchangeStatus,
             .exchangeHistory,
             .exchangeHistoryDelta,
             .onrampCurrencies,
             .onrampCountries,
             .onrampCountryByIP,
             .onrampPaymentMethods,
             .onrampQuote,
             .onrampData,
             .onrampStatus,
             .onrampHistory,
             .onrampHistoryDelta:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .assets(let request): .requestJSONEncodable(request)
        case .pairs(let request): .requestJSONEncodable(request)
        case .exchangeSent(let request): .requestJSONEncodable(request)
        case .providers: .requestPlain
        case .exchangeQuote(let request): .requestParameters(request)
        case .exchangeData(let request): .requestParameters(request)
        case .exchangeStatus(let request): .requestParameters(request)
        case .exchangeHistory(let request): .requestParameters(request)
        case .exchangeHistoryDelta(let request): .requestParameters(request)
        case .onrampCurrencies: .requestPlain
        case .onrampCountries: .requestPlain
        case .onrampCountryByIP: .requestPlain
        case .onrampPaymentMethods: .requestPlain
        case .onrampPairs(let request): .requestJSONEncodable(request)
        case .onrampQuote(let request): .requestParameters(request)
        case .onrampData(let request): .requestParameters(request)
        case .onrampNativePaymentData(let request): .requestJSONEncodable(request)
        case .onrampStatus(let request): .requestParameters(request)
        case .onrampHistory(let request): .requestParameters(request)
        case .onrampHistoryDelta(let request): .requestParameters(request)
        }
    }

    var headers: [String: String]? { nil }
}
