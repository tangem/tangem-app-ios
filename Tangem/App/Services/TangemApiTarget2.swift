//
//  TangemApiTarget2.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

#warning("[REDACTED_TODO_COMMENT]")
enum TangemApiTarget2: TargetType {
    case checkContractAddress(contractAddress: String, networkId: String)
    
    var baseURL: URL {URL(string: "https://api.tangem-tech.com")!}
    
    var path: String {
        switch self {
        case .checkContractAddress:
            return "/coins/check-address"
        }
    }
    
    var method: Moya.Method { .get }
    
    var task: Task {
        switch self {
        case .checkContractAddress(let contractAddress, let networkId):
            return .requestParameters(parameters: ["contractAddress": contractAddress,
                                                   "networkId": networkId],
                                      encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        // [REDACTED_TODO_COMMENT]
        return nil
    }
}
