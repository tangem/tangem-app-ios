//
//  CoinMarketCapService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import BlockchainSdk

enum CoinMarketCapTarget: TargetType {
    case rate(amount: Decimal, symbol: String, convert: [String], apiKey: String)
    
    var baseURL: URL {URL(string: "https://pro-api.coinmarketcap.com/")!}
    
    var path: String { "v1/tools/price-conversion" }
    
    var method: Moya.Method { .get }
    
    var sampleData: Data { Data() }
    
    var task: Task {
        switch self {
        case .rate(let amount, let symbol, let convert, _):
            return .requestParameters(parameters: ["amount" : amount,
                                                   "symbol" : symbol,
                                                   "convert" : convert.joined(separator: ",")],
                                      encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .rate(_, _, _, let apiKey):
            return ["X-CMC_PRO_API_KEY": apiKey]
        }
    }
}


struct RateInfoResponse: Codable {
    let status: Status
    let data: RateData
}

struct RateData: Codable {
    let quote: [String:CurrencyRate]
}

struct CurrencyRate: Codable {
    let price: Decimal
}


struct Status: Codable {
    let timestamp: String
    let errorCode: Int
    let errorMessage: String?
    let elapsed: Int
    let creditCount: Int
    let notice: String?
    
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case errorMessage = "error_message"
        case creditCount = "credit_count"
        case timestamp
        case elapsed
        case notice
    }
}


class CoinMarketCapService {
    enum FiatCurrencies: String, CaseIterable {
        case usd = "USD"
    }
    
    let apiKey: String
    let provider = MoyaProvider<CoinMarketCapTarget>(plugins: [NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration.verboseConfiguration)])
    
    internal init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func loadRates(for currencies: [String: Decimal], convertTo: [FiatCurrencies] = [FiatCurrencies.usd]) -> AnyPublisher<[String: [String: Decimal]], MoyaError> {
        currencies
            .publisher
            .setFailureType(to: MoyaError.self)
            .flatMap { [unowned self] item in
                return self.provider
                    .requestPublisher(.rate(amount: item.value, symbol: item.key, convert: convertTo.map { $0.rawValue }, apiKey: self.apiKey))
                    .filterSuccessfulStatusAndRedirectCodes()
                    .map(RateInfoResponse.self)
                    .map { (item.key, $0.data.quote.mapValues {  $0.price }) }
        }
        .collect()
        .map { $0.reduce(into: [String: [String: Decimal]]()) { $0[$1.0] = $1.1 } }
        .eraseToAnyPublisher()
    }
}
