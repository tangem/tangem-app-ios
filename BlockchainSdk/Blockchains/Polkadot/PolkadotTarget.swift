//
//  PolkadotTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

enum PolkadotBlockhashType {
    case genesis
    case latest
}

struct PolkadotTarget: JSONRPCTargetType {
    static var id: Int = 0

    enum Target {
        case storage(key: String)
        case blockhash(type: PolkadotBlockhashType)
        case header(hash: String)
        case accountNextIndex(address: String)
        case runtimeVersion(url: URL)
        case queryInfo(extrinsic: String)
        case submitExtrinsic(extrinsic: String)
    }

    let node: NodeInfo
    let target: Target

    var baseURL: URL {
        node.url
    }

    var path: String {
        return ""
    }

    var method: Moya.Method {
        return .post
    }

    var params: AnyEncodable {
        switch target {
        case .storage(let key):
            return AnyEncodable([key])
        case .blockhash(.genesis):
            return AnyEncodable([0])
        case .header(let hash):
            return AnyEncodable([hash])
        case .accountNextIndex(let address):
            return AnyEncodable([address])
        case .runtimeVersion, .blockhash(.latest):
            return .emptyArray
        case .queryInfo(let extrinsic):
            return AnyEncodable(["TransactionPaymentApi_query_info", extrinsic])
        case .submitExtrinsic(let extrinsic):
            return AnyEncodable([extrinsic])
        }
    }

    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        if let headersKeyInfo = node.headers {
            headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
        }
        return headers
    }

    var rpcMethod: String {
        switch target {
        case .storage:
            return "state_getStorage"
        case .blockhash:
            return "chain_getBlockHash"
        case .header:
            return "chain_getHeader"
        case .accountNextIndex:
            return "system_accountNextIndex"
        case .runtimeVersion:
            return "state_getRuntimeVersion"
        case .queryInfo:
            return "state_call"
        case .submitExtrinsic:
            return "author_submitExtrinsic"
        }
    }
}

extension PolkadotTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        rpcMethod
    }
}
