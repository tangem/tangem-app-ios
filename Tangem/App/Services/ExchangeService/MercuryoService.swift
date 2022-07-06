//
//  MercuryoService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

fileprivate enum QueryKey: String {
    case widget_id
    case type
    case currency
    case address
    case lang
    case fix_currency
    case return_url
}


fileprivate struct MercuryoCurrencyResponse: Decodable {
    let data: MercuryoData
}

fileprivate struct MercuryoData: Decodable {
    let crypto: [String]
}


class MercuryoService {
    @Injected(\.keysManager) var keysManager: KeysManager
    
    private var widgetId: String { keysManager.mercuryoWidgetId }
    
    private var availableCryptoCurrencyCodes: [String] = []
    
    private var bag: Set<AnyCancellable> = []
    
    init() {}
    
    deinit {
        print("MercuryoService deinit")
    }
}

extension MercuryoService: ExchangeService {
    var successCloseUrl: String { "https://success.tangem.com" }
    
    var sellRequestUrl: String {
        return ""
    }
    
    func canBuy(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        guard availableCryptoCurrencyCodes.contains(currencySymbol) else {
            return false
        }
        
        switch amountType {
        case .token:
            if case .ethereum = blockchain {
                return true
            } else {
                return false
            }
        default:
            return true
        }
    }
    
    func canSell(_ currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        return false
    }
    
    func getBuyUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard
            canBuy(currencySymbol, amountType: amountType, blockchain: blockchain)
        else {
            return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "exchange.mercuryo.io"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .widget_id, value: widgetId.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .type, value: "buy"))
        queryItems.append(.init(key: .currency, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .address, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .fix_currency, value: "true"))
        queryItems.append(.init(key: .return_url, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        
        if let languageCode = Locale.current.languageCode {
            queryItems.append(.init(key: .lang, value: languageCode))
        }
        
        urlComponents.percentEncodedQueryItems = queryItems
        
        let url = urlComponents.url
        return url
    }
    
    func getSellUrl(currencySymbol: String, amountType: Amount.AmountType, blockchain: Blockchain, walletAddress: String) -> URL? {
        fatalError("[REDACTED_TODO_COMMENT]")
    }
    
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        return nil
    }
    
    func initialize() {
        let request = URLRequest(url: URL(string: "https://api.mercuryo.io/v1.6/lib/currencies")!)
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        URLSession(configuration: config).dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: MercuryoCurrencyResponse.self, decoder: JSONDecoder())
            .sink { _ in
                
            } receiveValue: { [unowned self] response in
                self.availableCryptoCurrencyCodes = response.data.crypto
            }
            .store(in: &bag)
    }
}

extension URLQueryItem {
    fileprivate init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}
