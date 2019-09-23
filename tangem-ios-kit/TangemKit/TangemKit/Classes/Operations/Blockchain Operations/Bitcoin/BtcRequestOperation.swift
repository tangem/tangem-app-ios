//
//  BtcRequestOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

protocol BtcEndpoint {
    var url: String {get}
    var testUrl: String {get}
    var method: String {get}
    var body: Data? {get}
    var headers: [String:String] {get}
}

class BtcRequestOperation<T>: GBAsyncOperation where T: Decodable {
    
    var useTestNet = false
    let endpoint: BtcEndpoint
    var completion: (TangemObjectResult<T>) -> Void
    
    init(endpoint: BtcEndpoint, completion: @escaping (TangemObjectResult<T>) -> Void) {
        self.endpoint = endpoint
        self.completion = completion
    }
    
    override func main() {
        let url = URL(string: useTestNet ? endpoint.testUrl : endpoint.url)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        urlRequest.httpBody = endpoint.body
        for header in endpoint.headers {
            urlRequest.addValue(header.key, forHTTPHeaderField: header.value)
        }
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                let response: T? = (try? JSONDecoder().decode(T.self, from: data)) ?? String(data: data, encoding: .utf8) as? T
                if response == nil {
                    self.failOperationWith(error: "Mapping error")
                } else {
                    self.completeOperationWith(response: response!)
                }
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
        
        task.resume()
    }
    
    func completeOperationWith(response: T) {
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
