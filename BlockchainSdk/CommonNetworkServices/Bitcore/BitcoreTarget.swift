//
//  BitcoreTarget.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya

enum BitcoreTarget: TargetType {
    case balance(address: String)
    case unspents(address: String)
    case tx(hash: String)
    case inputsOutputs(txHash: String)
    case send(txHex: String)

    var baseURL: URL {
        return URL(string: "https://ducapi.rocknblock.io/api/DUC/mainnet")!
    }

    var path: String {
        switch self {
        case .balance(let address):
            return "/address/\(address)/balance"
        case .unspents(let address):
            return "/address/\(address)/"
        case .tx(let hash):
            return "/tx/\(hash)/"
        case .inputsOutputs(let hash):
            return "/tx/\(hash)/coins"
        case .send:
            return "tx/send"
        }
    }

    var method: Moya.Method {
        switch self {
        case .balance, .unspents, .tx, .inputsOutputs:
            return .get
        case .send:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .balance, .tx, .inputsOutputs:
            return .requestPlain
        case .unspents:
            return .requestParameters(parameters: ["unspent": "true"], encoding: URLEncoding.default)
        case .send(let txHex):
            return .requestParameters(parameters: ["rawTx": [txHex]], encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
