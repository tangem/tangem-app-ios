//
//  TopupService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Alamofire

class MoonPayService {    
	private let keys: MoonPayKeys
    
    private let availableToBuy: Set<String> = [
        "ZRX", "AAVE", "ALGO", "AXS", "BAT", "BNB", "BUSD", "BTC", "BCH", "BTT", "ADA", "CELO", "CUSD", "LINK", "CHZ", "COMP", "ATOM", "DAI", "DASH", "MANA", "DGB", "DOGE", "EGLD",
        "ENJ", "EOS", "ETC", "ETH", "KETH", "RINKETH", "FIL", "HBAR", "MIOTA", "KAVA", "KLAY", "LBC", "LTC", "LUNA", "MKR", "OM", "MATIC", "NANO", "NEAR", "XEM", "NEO", "NIM", "OKB",
        "OMG", "ONG", "ONT", "DOT", "QTUM", "RVN", "RFUEL", "KEY", "SRM", "SOL", "XLM", "STMX", "SNX", "KRT", "UST", "USDT", "XTZ", "RUNE", "SAND", "TOMO", "AVA", "TRX", "TUSD", "UNI",
        "USDC", "UTK", "VET", "WAXP", "WBTC", "XRP", "ZEC", "ZIL"
    ]
    private let availableToSell: Set<String> = [
        "BTC", "ETH", "BCH"
    ]
	
	init(keys: MoonPayKeys) {
		self.keys = keys
	}
    
    deinit {
        print("MoonPay deinit")
    }
}

extension MoonPayService: ExchangeService {
    
    var buyCloseUrl: String {
        "https://success.tangem.com"
    }
    
    var sellCloseUrl: String { "" }
    
    func canBuy(_ currency: String) -> Bool {
        availableToBuy.contains(currency)
    }
    
    func canSell(_ currency: String) -> Bool {
        availableToSell.contains(currency)
    }
    
    func getBuyUrl(currencySymbol: String, walletAddress: String) -> URL? {
        guard canBuy(currencySymbol) else {
            return nil
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "buy.moonpay.io"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "apiKey", value: keys.apiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(URLQueryItem(name: "currencyCode", value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(URLQueryItem(name: "walletAddress", value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(URLQueryItem(name: "redirectURL", value: buyCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        
        urlComponents.percentEncodedQueryItems = queryItems
        let queryData = "?\(urlComponents.percentEncodedQuery!)".data(using: .utf8)!
        let secretKey = keys.secretApiKey.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: queryData, using: SymmetricKey(data: secretKey))
        
        queryItems.append(URLQueryItem(name: "signature", value: Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        urlComponents.percentEncodedQueryItems = queryItems
        
        let url = urlComponents.url!
        return url
    }
    
    func getSellUrl(currencySymbol: String, walletAddress: String) -> URL? {
        fatalError()
    }
    
    
}
