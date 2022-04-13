//
//  OnramperService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

fileprivate enum QueryKey: String {
    case apiKey,
         onlyCryptos,
         defaultCrypto,
         defaultFiat,
         wallets,
         onlyGateways,
         language,
         redirectURL
}


fileprivate struct OnramperGatewaysResponse: Decodable {
    let gateways: [OnramperGateway]
}

fileprivate struct OnramperGateway: Decodable {
    let identifier: String
    let cryptoCurrencies: [OnramperCryptoCurrency]
}

fileprivate struct OnramperCryptoCurrency: Decodable {
    let id: String
    let code: String
    let network: String?
}


class OnramperService {
    private let key: String
    
    private var availableCryptoCurrencies: [OnramperCryptoCurrency] = []
    
    private let canBuyCrypto = true
    private let canSellCrypto = false
    private var bag: Set<AnyCancellable> = []
    
    init(key: String) {
        self.key = key
        setupService()
    }
    
    deinit {
        print("OnramperService deinit")
    }
    
    private func setupService() {
        var request = URLRequest(url: URL(string: "https://onramper.tech/gateways")!)
        request.addValue("Basic \(key)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: OnramperGatewaysResponse.self, decoder: JSONDecoder())
            .sink { _ in
                
            } receiveValue: { [unowned self] response in
                let currencies = response.gateways.reduce([]) {
                    $0 + $1.cryptoCurrencies
                }
                
                self.availableCryptoCurrencies = currencies
            }
            .store(in: &bag)
    }
    
    private func currencyId(currencySymbol: String, blockchain: Blockchain) -> String? {
        let currencies = availableCryptoCurrencies.filter { $0.code == currencySymbol }
        
        let currency: OnramperCryptoCurrency?
        if let onramperNetworkId = blockchain.onramperNetworkId {
            let networkCurrencies = currencies.filter { $0.network == onramperNetworkId }
            currency = networkCurrencies.first
        } else {
            currency = currencies.first
        }
        
        return currency?.id
    }
}

extension OnramperService: ExchangeService {
    var successCloseUrl: String { "https://success.tangem.com" }
    
    var sellRequestUrl: String {
        return ""
    }
    
    func canBuy(_ currencySymbol: String, blockchain: Blockchain) -> Bool {
        return canBuyCrypto && currencyId(currencySymbol: currencySymbol, blockchain: blockchain) != nil
    }
    
    func canSell(_ currencySymbol: String, blockchain: Blockchain) -> Bool {
        return false
    }
    
    func getBuyUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard
            canBuy(currencySymbol, blockchain: blockchain),
            let currencyID = currencyId(currencySymbol: currencySymbol, blockchain: blockchain)
        else {
            return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "widget.onramper.com"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: key.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .defaultCrypto, value: currencyID.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .wallets, value: "\(blockchain.currencySymbol):\(walletAddress)".addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        queryItems.append(.init(key: .defaultFiat, value: "USD".addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        if let languageCode = Locale.current.languageCode {
            queryItems.append(.init(key: .language, value: languageCode))
        }
        
        urlComponents.percentEncodedQueryItems = queryItems
        
        let url = urlComponents.url
        return url
    }
    
    func getSellUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        fatalError("[REDACTED_TODO_COMMENT]")
    }
    
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }
}

extension URLQueryItem {
    fileprivate init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}

fileprivate extension Blockchain {
    var onramperNetworkId: String? {
        switch self {
        case .bsc:
            return "BEP-20"
        case .binance:
            return "BEP-2"
        default:
            return nil
        }
    }
}
