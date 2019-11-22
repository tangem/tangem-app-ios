//
//  TangemAPIClient.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum TangemApiError: Error {
    case invalidStatusCode
}

public enum TangemNetworkResult {
    case success(Data)
    case failure(Error)
}

public enum TangemObjectResult<T> {
    case success(T)
    case failure(Error)
}

class TangemAPIClient {
    
    static func dataDask(request: URLRequest, completion: @escaping (TangemNetworkResult) -> Void) -> URLSessionTask {
        var request = request
        print("request to: \(request.url!)")
        
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return URLSession.shared.dataTask(with: request) { data, response, error in
            guard let unwrappedData = data,
                let unwrappedResponse = response as? HTTPURLResponse,
                (200 ..< 300) ~= unwrappedResponse.statusCode,
                error == nil else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    let description = (data == nil ? "unknown description" : String(data: data!, encoding: .utf8)) ?? "unknown description"
                    let errorString = "code: \(code), descr: \(description)"
                    print(errorString)
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure("\(errorString), \(error.localizedDescription)"))
                            print(error)
                        } else {
                            completion(.failure(errorString))
                        }
                        
                    }
                    return
            }
            
            print("status code: \(unwrappedResponse.statusCode), response: \(String(data: unwrappedData, encoding: .utf8))")
                    
            DispatchQueue.main.async {
                completion(.success(unwrappedData))
            }
        }
        
    }
    
}
