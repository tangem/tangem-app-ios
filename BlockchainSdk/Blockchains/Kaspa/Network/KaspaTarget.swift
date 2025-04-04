//
//  KaspaTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KaspaTarget: TargetType {
    let request: Request
    let baseURL: URL

    var path: String {
        switch request {
        case .blueScore:
            return "info/virtual-chain-blue-score"
        case .balance(let address):
            return "addresses/\(address)/balance"
        case .utxos(let address):
            return "addresses/\(address)/utxos"
        case .transactions:
            return "transactions"
        case .transaction(let hash, _):
            return "transactions/\(hash)"
        case .mass:
            return "transactions/mass"
        case .feeEstimate:
            return "info/fee-estimate"
        }
    }

    var method: Moya.Method {
        switch request {
        case .blueScore, .balance, .utxos, .transaction, .feeEstimate:
            return .get
        case .transactions, .mass:
            return .post
        }
    }

    var task: Moya.Task {
        switch request {
        case .blueScore, .balance, .utxos, .feeEstimate:
            return .requestPlain
        case .transaction(_, let options):
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return .requestParameters(options, encoder: encoder)
        case .transactions(let transaction):
            return .requestJSONEncodable(transaction)
        case .mass(let data):
            return .requestJSONEncodable(data)
        }
    }

    var headers: [String: String]? {
        nil
    }
}

extension KaspaTarget {
    enum Request {
        case blueScore
        case balance(address: String)
        case utxos(address: String)
        case transactions(transaction: KaspaDTO.Send.Request)
        case transaction(hash: String, request: KaspaDTO.TransactionInfo.Request)
        case mass(data: KaspaDTO.Send.Request.Transaction)
        case feeEstimate
    }
}
