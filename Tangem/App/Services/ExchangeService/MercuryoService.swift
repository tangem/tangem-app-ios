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
import TangemSdk

fileprivate enum QueryKey: String {
    case widget_id
    case type
    case currency
    case address
    case signature
    case lang
    case fix_currency
    case return_url
}


fileprivate struct MercuryoCurrencyResponse: Decodable {
    let data: MercuryoData
}

fileprivate struct MercuryoData: Decodable {
    let crypto: [String]
    let config: MercuryoConfig
}

fileprivate struct MercuryoConfig: Decodable {
    let base: [String: String]
}


class MercuryoService {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    private var widgetId: String {
        keysManager.mercuryoWidgetId
    }
    
    private var secret: String {
        keysManager.mercuryoSecret
    }

    private var isTestnet: Bool {
        cardsRepository.lastScanResult.cardModel?.cardInfo.isTestnet ?? false
    }

    private var availableCurves: [EllipticCurve] {
        cardsRepository.lastScanResult.card?.walletCurves ?? []
    }
    
    private var availableCryptoCurrencyCodes: [String] = []
    private var networkCodeByCurrencyCode: [String: String] = [:]
    
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
        
        if let mercuryoNetworkCurrencyCode = networkCodeByCurrencyCode[currencySymbol],
           let mercuryoBlockchain = self.blockchain(for: mercuryoNetworkCurrencyCode),
           mercuryoBlockchain == blockchain
        {
            return true
        } else {
            return false
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
        queryItems.append(.init(key: .signature, value: signature(for: walletAddress).addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
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
                self.networkCodeByCurrencyCode = response.data.config.base
            }
            .store(in: &bag)
    }
    
    private func blockchain(for currencyCode: String) -> Blockchain? {
        let supportedBlockchains = SupportedTokenItems()
            .blockchains(for: availableCurves, isTestnet: isTestnet)
            .filter {
                // Arbitrum uses ETH, binance uses BNB.
                // Both are in conflict with the other cryptocurrencies.
                switch $0 {
                case .arbitrum, .binance:
                    return false
                default:
                    return true
                }
            }
        
        return supportedBlockchains.first {
            $0.currencySymbol == currencyCode
        }
    }
    
    private func signature(for address: String) -> String {
        (address + secret).sha512()
    }
}

extension URLQueryItem {
    fileprivate init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}
