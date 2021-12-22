//
//  TopupService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Alamofire
import Combine
import BlockchainSdk

fileprivate enum QueryKey: String {
    case apiKey,
         currencyCode,
         walletAddress,
         redirectURL,
         baseCurrencyCode,
         refundWalletAddress,
         signature,
         baseCurrencyAmount,
         depositWalletAddress
}

fileprivate struct IpCheckResponse: Decodable {
    let countryCode: String
    let stateCode: String
    let isMoonpayAllowed: Bool
    let isBuyAllowed: Bool
    let isSellAllowed: Bool
    
    private enum CodingKeys: String, CodingKey {
        case countryCode = "alpha3",
             isMoonpayAllowed = "isAllowed",
             stateCode = "state"
        case isBuyAllowed, isSellAllowed
    }
}

fileprivate struct MoonpayCurrency: Decodable {
    enum CurrencyType: String, Decodable {
        case crypto, fiat
    }
    
    let type: CurrencyType
    let code: String
    let supportsLiveMode: Bool?
    let isSuspended: Bool?
    let isSupportedInUS: Bool?
    let isSellSupported: Bool?
    let notAllowedUSStates: [String]?
}

class MoonPayService {
	private let keys: MoonPayKeys
    
    private var availableToBuy: Set<String> = [
        "ZRX", "AAVE", "ALGO", "AXS", "BAT", "BNB", "BUSD", "BTC", "BCH", "BTT", "ADA", "CELO", "CUSD", "LINK", "CHZ", "COMP", "ATOM", "DAI", "DASH", "MANA", "DGB", "DOGE", "EGLD",
        "ENJ", "EOS", "ETC", "ETH", "KETH", "RINKETH", "FIL", "HBAR", "MIOTA", "KAVA", "KLAY", "LBC", "LTC", "LUNA", "MKR", "OM", "MATIC", "NANO", "NEAR", "XEM", "NEO", "NIM", "OKB",
        "OMG", "ONG", "ONT", "DOT", "QTUM", "RVN", "RFUEL", "KEY", "SRM", "SOL", "XLM", "STMX", "SNX", "KRT", "UST", "USDT", "XTZ", "RUNE", "SAND", "TOMO", "AVA", "TRX", "TUSD", "UNI",
        "USDC", "UTK", "VET", "WAXP", "WBTC", "XRP", "ZEC", "ZIL"
    ]
    private var availableToSell: Set<String> = [
        "BTC", "ETH", "BCH"
    ]
    
    private(set) var canBuyCrypto = true
    private(set) var canSellCrypto = true
    private var bag: Set<AnyCancellable> = []
	
	init(keys: MoonPayKeys) {
		self.keys = keys
        setupService()
	}
    
    deinit {
        print("MoonPay deinit")
    }
    
    private func makeSignature(for components: URLComponents) -> URLQueryItem {
        let queryData = "?\(components.percentEncodedQuery!)".data(using: .utf8)!
        let secretKey = keys.secretApiKey.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: queryData, using: SymmetricKey(data: secretKey))
        
        return .init(key: .signature, value: Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed))
    }
    
    private func setupService() {
        Publishers.Zip(
            URLSession.shared.dataTaskPublisher(for: URL(string: ("https://api.moonpay.com/v4/ip_address?" + QueryKey.apiKey.rawValue + "=" + keys.apiKey))!),
            URLSession.shared.dataTaskPublisher(for: URL(string: "https://api.moonpay.com/v3/currencies?" + QueryKey.apiKey.rawValue + "=" + keys.apiKey)!)
        )
        .sink(receiveCompletion: { _ in }) { [weak self] (ipOutput, currenciesOutput) in
            guard let self = self else { return }
            let decoder = JSONDecoder()
            var countryCode: String = ""
            var stateCode: String = ""
            do {
                let decodedResponse = try decoder.decode(IpCheckResponse.self, from: ipOutput.data)
                self.canBuyCrypto = decodedResponse.isBuyAllowed
                self.canSellCrypto = decodedResponse.isSellAllowed
                countryCode = decodedResponse.countryCode
                stateCode = decodedResponse.stateCode
            } catch {
                print("Failed to check IP address: \(error)")
            }
            do {
                var currenciesToBuy = Set<String>()
                var currenciesToSell = Set<String>()
                let decodedResponse = try decoder.decode([MoonpayCurrency].self, from: currenciesOutput.data)
                decodedResponse.forEach {
                    guard
                        $0.type == .crypto,
                        let isSuspended = $0.isSuspended, !isSuspended,
                        let supportsLiveMode = $0.supportsLiveMode, supportsLiveMode
                    else { return }
                    
                    if countryCode == "USA" {
                        if let isSupportedInUS = $0.isSupportedInUS, !isSupportedInUS {
                            return
                        }
                        
                        if let notAllowedUSStates = $0.notAllowedUSStates, notAllowedUSStates.contains(stateCode) {
                            return
                        }
                    }
                    
                    currenciesToBuy.insert($0.code.uppercased())
                    
                    if let isSellSupported = $0.isSellSupported, isSellSupported {
                        currenciesToSell.insert($0.code.uppercased())
                    }
                }
                self.availableToBuy = currenciesToBuy
                self.availableToSell = currenciesToSell
            } catch {
                print("Failed to load currencies: \(error)")
            }
        }
        .store(in: &bag)
    }
}

extension MoonPayService: ExchangeService {
    
    var successCloseUrl: String { "https://success.tangem.com" }
    
    var sellRequestUrl: String {
        "https://sell-request.tangem.com"
    }
    
    func canBuy(_ currency: String, blockchain: Blockchain) -> Bool {
        if currency.uppercased() == "BNB" && (blockchain == .bsc(testnet: true) || blockchain == .bsc(testnet: false)) {
            return false
        }
        
        return availableToBuy.contains(currency.uppercased()) && canBuyCrypto
    }
    
    func canSell(_ currency: String, blockchain: Blockchain) -> Bool {
        if currency.uppercased() == "BNB" && (blockchain == .bsc(testnet: true) || blockchain == .bsc(testnet: false)) {
            return false
        }
        
        return availableToSell.contains(currency.uppercased()) && canSellCrypto
    }
    
    func getBuyUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard canBuy(currencySymbol, blockchain: blockchain) else {
            return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "buy.moonpay.io"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .currencyCode, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .walletAddress, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: successCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        queryItems.append(.init(key: .baseCurrencyCode, value: "USD".addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        urlComponents.percentEncodedQueryItems = queryItems
        let signatureItem = makeSignature(for: urlComponents)
        queryItems.append(signatureItem)
        urlComponents.percentEncodedQueryItems = queryItems
        
        let url = urlComponents.url
        return url
    }
    
    func getSellUrl(currencySymbol: String, blockchain: Blockchain, walletAddress: String) -> URL? {
        guard canSell(currencySymbol, blockchain: blockchain) else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "sell.moonpay.com"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(.init(key: .apiKey, value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .baseCurrencyCode, value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .refundWalletAddress, value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(.init(key: .redirectURL, value: sellRequestUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        
        components.percentEncodedQueryItems = queryItems
        let signature = makeSignature(for: components)
        queryItems.append(signature)
        components.percentEncodedQueryItems = queryItems
        
        let url = components.url
        return url
    }
    
    func extractSellCryptoRequest(from data: String) -> SellCryptoRequest? {
        guard
            data.starts(with: sellRequestUrl),
            let url = URL(string: data),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let items = components.queryItems,
            let currencyCode = items.first(where: { $0.name == QueryKey.baseCurrencyCode.rawValue })?.value,
            let amountStr = items.first(where: { $0.name == QueryKey.baseCurrencyAmount.rawValue })?.value,
            let amount = Decimal(string: amountStr),
            let targetAddress = items.first(where: { $0.name == QueryKey.depositWalletAddress.rawValue })?.value
        else {
            return nil
        }

        return .init(currencyCode: currencyCode, amount: amount, targetAddress: targetAddress)
    }
    
}

extension URLQueryItem {
    fileprivate init(key: QueryKey, value: String?) {
        self.init(name: key.rawValue, value: value)
    }
}
