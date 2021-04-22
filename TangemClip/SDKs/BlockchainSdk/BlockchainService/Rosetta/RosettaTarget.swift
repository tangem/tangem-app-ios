//
//  RosettaTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum RosettaUrl: String {
    case tangemRosetta = "https://ada.tangem.com"
}

enum RosettaTarget: TargetType {
    case address(baseUrl: RosettaUrl, addressBody: RosettaAddressBody)
    case submitTransaction(baseUrl: RosettaUrl, submitBody: RosettaSubmitBody)
    
    var baseURL: URL {
        switch self {
        case .address(let url, _), .submitTransaction(let url, _):
            return URL(string: url.rawValue)!
        }
    }
    
    var path: String {
        switch self {
        case .address:
            return "/account/balance"
        case .submitTransaction:
            return "/construction/submit"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .submitTransaction:
            return .post
        }
    }
    
    var sampleData: Data {
        Data()
    }
    
    var task: Task {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        switch self {
        case .address(_, let body):
            return .requestCustomJSONEncodable(body, encoder: encoder)
        case .submitTransaction(_, let body):
            return .requestCustomJSONEncodable(body, encoder: encoder)
        }
    }
    
    var headers: [String : String]? {
        nil
    }
}
