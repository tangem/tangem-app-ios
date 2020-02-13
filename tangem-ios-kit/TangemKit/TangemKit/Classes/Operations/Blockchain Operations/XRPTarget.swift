//
//  XRPTarget.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya

enum XrpTarget: TargetType {
    case accountInfo(account:String)
    case unconfirmed(account:String)
    case submit(tx:String)
    case fee
    case reserve
    
    var baseURL: URL {
        return URL(string: "https://s1.ripple.com:51234")!
    }
    
    var path: String {""}
    
    var method: Moya.Method { .post }
    
    var sampleData: Data { return Data() }
    
    var task: Task {
        switch self {
        case .accountInfo(let account):
            let parameters: [String: Any] = [
                "method" : "account_info",
                "params": [
                    [
                        "account" : account,
                        "ledger_index" : "validated"
                    ]
                ]
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .unconfirmed(let account):
            let parameters: [String: Any] = [
                "method" : "account_info",
                "params": [
                    [
                        "account" : account,
                        "ledger_index" : "current"
                    ]
                ]
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .submit(let tx):
            let parameters: [String: Any] = [
                "method" : "submit",
                "params": [
                    [
                        "tx_blob": tx
                    ]
                ]
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .fee:
            let parameters: [String: Any] = [
                "method" : "fee"
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .reserve:
            let parameters: [String: Any] = [
                "method" : "server_state"
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
