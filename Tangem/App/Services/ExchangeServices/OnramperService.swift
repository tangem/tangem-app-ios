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
    let code: String
}


class OnramperService {
    private let key: String
    
    private var availableSymbols: Set<String> = [
        "ZRX", "AAVE", "ALGO", "AXS", "BAT", "BNB", "BUSD", "BTC", "BCH", "BTT", "ADA", "CELO", "CUSD", "LINK", "CHZ", "COMP", "ATOM", "DAI", "DASH", "MANA", "DGB", "DOGE", "EGLD",
        "ENJ", "EOS", "ETC", "ETH", "KETH", "RINKETH", "FIL", "HBAR", "MIOTA", "KAVA", "KLAY", "LBC", "LTC", "LUNA", "MKR", "OM", "MATIC", "NANO", "NEAR", "XEM", "NEO", "NIM", "OKB",
        "OMG", "ONG", "ONT", "DOT", "QTUM", "RVN", "RFUEL", "KEY", "SRM", "SOL", "XLM", "STMX", "SNX", "KRT", "UST", "USDT", "XTZ", "RUNE", "SAND", "TOMO", "AVA", "TRX", "TUSD", "UNI",
        "USDC", "UTK", "VET", "WAXP", "WBTC", "XRP", "ZEC", "ZIL"
    ]
    
    private var availableGatewayIdentifiers: [String]?
    
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
                let availableSymbols = response.gateways.reduce([]) {
                    $0 + $1.cryptoCurrencies
                }.reduce([]) {
                    $0 + [$1.code]
                }
                
                self.availableSymbols = Set(availableSymbols)
                self.availableGatewayIdentifiers = response.gateways.map { $0.identifier }
            }
            .store(in: &bag)
    }
}

extension OnramperService: ExchangeService {
    var successCloseUrl: String { "https://success.tangem.com" }
    
    var sellRequestUrl: String {
        return ""
    }
    
    func canBuy(_ currency: String, blockchain: Blockchain) -> Bool {
        if currency.uppercased() == "BNB" && (blockchain == .bsc(testnet: true) || blockchain == .bsc(testnet: false)) {
            return false
        }
        
        return availableSymbols.contains(currency.uppercased()) && canBuyCrypto
    }
    
    func canSell(_ currency: String, blockchain: Blockchain) -> Bool {
        return false
    }
    
    func getBuyUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard canBuy(currencySymbol, blockchain: blockchain) else {
            return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "widget.onramper.com"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: key.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .defaultCrypto, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .onlyCryptos, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
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
