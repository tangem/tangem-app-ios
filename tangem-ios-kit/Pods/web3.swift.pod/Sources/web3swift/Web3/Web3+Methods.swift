//  web3swift
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation

public enum JSONRPCmethod: String, Encodable {
    
    case gasPrice = "eth_gasPrice"
    case blockNumber = "eth_blockNumber"
    case getNetwork = "net_version"
    case sendRawTransaction = "eth_sendRawTransaction"
    case sendTransaction = "eth_sendTransaction"
    case estimateGas = "eth_estimateGas"
    case call = "eth_call"
    case getTransactionCount = "eth_getTransactionCount"
    case getBalance = "eth_getBalance"
    case getCode = "eth_getCode"
    case getStorageAt = "eth_getStorageAt"
    case getTransactionByHash = "eth_getTransactionByHash"
    case getTransactionReceipt = "eth_getTransactionReceipt"
    case getAccounts = "eth_accounts"
    case getBlockByHash = "eth_getBlockByHash"
    case getBlockByNumber = "eth_getBlockByNumber"
    case personalSign = "eth_sign"
    case unlockAccount = "personal_unlockAccount"
    case createAccount = "personal_createAccount"
    case getLogs = "eth_getLogs"
    case getTxPoolInspect = "txpool_inspect"
    case getTxPoolStatus = "txpool_status"
    case getTxPoolContent = "txpool_content"

    
    public var requiredNumOfParameters: Int {
        get {
            switch self {
            case .call:
                return 2
            case .getTransactionCount:
                return 2
            case .getBalance:
                return 2
            case .getStorageAt:
                return 2
            case .getCode:
                return 2
            case .getBlockByHash:
                return 2
            case .getBlockByNumber:
                return 2
            case .gasPrice:
                return 0
            case .blockNumber:
                return 0
            case .getNetwork:
                return 0
            case .getAccounts:
                return 0
            case .getTxPoolStatus:
                return 0
            case .getTxPoolContent:
                return 0
            case .getTxPoolInspect:
                return 0
            default:
                return 1
            }
        }
    }
}

public struct JSONRPCRequestFabric {
    public static func prepareRequest(_ method: JSONRPCmethod, parameters: [Encodable]) -> JSONRPCrequest {
        var request = JSONRPCrequest()
        request.method = method
        let pars = JSONRPCparams(params: parameters)
        request.params = pars
        return request
    }
    
    public static func prepareRequest(_ method: InfuraWebsocketMethod, parameters: [Encodable]) -> InfuraWebsocketRequest {
        var request = InfuraWebsocketRequest()
        request.method = method
        let pars = JSONRPCparams(params: parameters)
        request.params = pars
        return request
    }
}
