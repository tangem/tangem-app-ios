//
//  BinanceChain.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire

 class BinanceChain {

    enum Endpoint: String {
        case mainnet = "https://dex.binance.org/api/v1"
        case testnet = "https://testnet-dex.binance.org/api/v1"
    }

    internal enum Path: String {
        case account = "account"
    }

    class Response {
        public var isError: Bool = false
        public var error: Error?
        public var sequence: Int = 0
        public var blockHeight: Int = 0
        public var account: BinanceAccount = BinanceAccount()
    }
    
    public typealias Completion = (BinanceChain.Response)->()

    private var endpoint: String = Endpoint.testnet.rawValue

    public init() {
    }

    public required convenience init(endpoint: URL) {
        self.init()
        self.endpoint = endpoint.absoluteString
    }

    public convenience init(endpoint: Endpoint) {
        self.init()
        self.endpoint = endpoint.rawValue
    }
    
    // MARK: - HTTP API

    public func account(address: String, completion: Completion? = nil) {
        let path = String(format: "%@/%@", Path.account.rawValue, address)
        self.api(path: path, method: .get, parser: BinanceAccountParser(), completion: completion)
    }

    // MARK: - Utils

    @discardableResult
    internal func api(path: String, method: Alamofire.HTTPMethod = .get, parser: BinanceAccountParser, completion: Completion? = nil) -> Request? {
        let url = String(format: "%@/%@", self.endpoint, path)
        let request = AF.request(url, method: method)
        request.validate(statusCode: 200..<300)
        request.responseData() { (http) -> Void in
            DispatchQueue.global(qos: .background).async {
                let response = BinanceChain.Response()

                switch http.result {
                case .success(let data):

                    do {
                        try parser.parse(response: response, data: data)
                    } catch {
                        response.isError = true
                        response.error = error
                    }

                case .failure(let error):

                    response.isError = true
                    response.error = error
                    if let data = http.data {
                        try? ErrorParser().parse(response: response, data: data)
                    }
                    
                }

                DispatchQueue.main.async {
                    if let completion = completion {
                        completion(response)
                    }
                }
                
            }

        }
        return request
    }
}

