//
//  BlockchainInfoApiTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchainInfoApiTarget: TargetType {
    case fees

    var baseURL: URL {
        return URL(string: "https://api.blockchain.info")!
    }
    
    var path: String {
        switch self {
        case .fees:
            return "/mempool/fees"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}

