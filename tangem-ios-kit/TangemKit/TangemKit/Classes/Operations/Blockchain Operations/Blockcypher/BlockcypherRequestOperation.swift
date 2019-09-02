//
//  BlockcypherRequestOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

public enum BlockcypherEndpoint {
    case address(address:String)
    case fee
    case send(txHex: String)
    

    private var randomToken: String {
        let tokens: [String] = ["aa8184b0e0894b88a5688e01b3dc1e82",
                                "56c4ca23c6484c8f8864c32fde4def8d",
                                "66a8a37c5e9d4d2c9bb191acfe7f93aa"]
        
        let tokenIndex = Int.random(in: 0...2)
        return tokens[tokenIndex]
    }
    
    public var url: String {
        switch self {
        case .fee:
            return "https://api.blockcypher.com/v1/btc/main"
        case .send(_):
            return "https://api.blockcypher.com/v1/btc/main/txs/push?token=\(randomToken)"
        case .address(let address):
            return "https://api.blockcypher.com/v1/btc/main/addrs/\(address)?unspentOnly=true&includeScript=true"
        }
    }
    
    public var testUrl: String {
        return url.replacingOccurrences(of: "main", with: "test3")
    }
    
    public var method: String {
        switch self {
        case .fee:
            return "GET"
        case .send(_):
            return "POST"
        case .address(_):
            return "GET"
        }
    }
    
    public var body: Data? {
        switch self {
        case .send(let txHex):
            let jsonDict = ["tx": txHex]
            let body = try? JSONSerialization.data(withJSONObject: jsonDict, options: [])
            return body
        default:
            return nil
        }
    }
}

class BlockcypherRequestOperation<T>: GBAsyncOperation where T: Decodable {
    
    var useTestNet = false
    let endpoint: BlockcypherEndpoint
    var completion: (TangemObjectResult<T?>) -> Void
    
    init(endpoint: BlockcypherEndpoint, completion: @escaping (TangemObjectResult<T?>) -> Void) {
        self.endpoint = endpoint
        self.completion = completion
    }
    
    override func main() {
        let url = URL(string: useTestNet ? endpoint.testUrl : endpoint.url)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.httpBody = endpoint.body
        
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                let response: T? = try? JSONDecoder().decode(T.self, from: data)
                self.completeOperationWith(response: response)
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
        
        task.resume()
    }
    
    func completeOperationWith(response: T?) {
        guard !isCancelled else {
            return
        }
        
        completion(.success(response))
        finish()
    }
    
    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }
        
        completion(.failure(error))
        finish()
    }
}
