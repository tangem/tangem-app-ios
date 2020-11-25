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

class TopupService {
    var config: AppConfig!
    
    let topupCloseUrl = "https://success.tangem.com"
    
    func getTopupURL(currencySymbol: String, walletAddress: String) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "buy.moonpay.io"
        
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "apiKey", value: config.moonPayApiKey.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(URLQueryItem(name: "currencyCode", value: currencySymbol.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(URLQueryItem(name: "walletAddress", value: walletAddress.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        queryItems.append(URLQueryItem(name: "redirectURL", value: topupCloseUrl.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)))
        
        urlComponents.percentEncodedQueryItems = queryItems
        let queryData = "?\(urlComponents.percentEncodedQuery!)".data(using: .utf8)!
        let secretKey = config.moonPaySecretApiKey.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: queryData, using: SymmetricKey(data: secretKey))
        
        queryItems.append(URLQueryItem(name: "signature", value: Data(signature).base64EncodedString().addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)))
        urlComponents.percentEncodedQueryItems = queryItems
        
        let url = urlComponents.url!
        print(url)
        return url
    }
}
