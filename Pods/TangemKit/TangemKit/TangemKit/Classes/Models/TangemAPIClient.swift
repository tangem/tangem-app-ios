//
//  TangemAPIClient.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON

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
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,                            
                let response = response as? HTTPURLResponse,
                (200 ..< 300) ~= response.statusCode,
                error == nil else {
                    DispatchQueue.main.async {
                        completion(.failure(error!))
                    }
                    return
            }
            
            DispatchQueue.main.async {
                completion(.success(data))
            }
        }
        
    }
    
}
