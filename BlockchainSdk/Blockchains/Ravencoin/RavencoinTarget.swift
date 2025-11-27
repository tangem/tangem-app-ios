//
//  RavencoinTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct RavencoinTarget {
    let node: NodeInfo
    let target: Target
}

extension RavencoinTarget: TargetType {
    enum Target {
        case wallet(address: String)
        case utxo(address: String)
        case fees(request: RavencoinDTO.Fee.Request)
        case transactions(request: RavencoinDTO.AddressInfo.Request)
        case transaction(id: String)
        case send(transaction: RavencoinDTO.Send.Request)
    }

    var baseURL: URL {
        node.url
    }

    var path: String {
        switch target {
        case .wallet(let address):
            return "addr/\(address)"
        case .utxo(let address):
            return "addrs/\(address)/utxo"
        case .fees:
            return "utils/estimatesmartfee"
        case .transaction(let id):
            return "tx/\(id)"
        case .send:
            return "tx/send"
        case .transactions:
            return "txs"
        }
    }

    var method: Moya.Method {
        switch target {
        case .send:
            return .post
        case .wallet, .utxo, .transaction, .fees, .transactions:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .fees(let request):
            return .requestParameters(request)
        case .transactions(let request):
            return .requestParameters(request)
        case .send(let transaction):
            return .requestJSONEncodable(transaction)
        case .wallet, .utxo, .transaction:
            return .requestPlain
        }
    }

    /// Workaround for API
    var headers: [String: String]? {
        ["User-Agent": "Mozilla/5.0 Version/16.1 Safari/605.1.15"]
    }
}
