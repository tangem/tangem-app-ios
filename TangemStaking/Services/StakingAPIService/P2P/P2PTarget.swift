//
//  P2PTarget.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

// MARK: - P2PTarget

struct P2PTarget {
    let apiKey: String
    let target: Target
    let network: P2PNetwork

    enum Target {
        /// Get the list of vaults for a network
        case getVaultsList
        /// Get account summary for a delegator in a vault
        case getAccountSummary(delegatorAddress: String, vaultAddress: String)
        /// Get rewards history for a delegator in a vault
        case getRewardsHistory(delegatorAddress: String, vaultAddress: String)
        /// Prepare deposit transaction
        case prepareDepositTransaction(request: P2PDTO.PrepareTransaction.Request)
        /// Prepare unstake transaction
        case prepareUnstakeTransaction(request: P2PDTO.PrepareTransaction.Request)
        /// Prepare withdraw transaction
        case prepareWithdrawTransaction(request: P2PDTO.PrepareTransaction.Request)
        /// Broadcast a signed transaction
        case broadcastTransaction(request: P2PDTO.BroadcastTransaction.Request)
    }
}

extension P2PTarget: TargetType {
    var baseURL: URL {
        network.apiBaseUrl
    }

    var path: String {
        switch target {
        case .getVaultsList:
            return "vaults"
        case .getAccountSummary(let delegatorAddress, let vaultAddress):
            return "account/\(delegatorAddress)/vault/\(vaultAddress)"
        case .getRewardsHistory(let delegatorAddress, let vaultAddress):
            return "account/\(delegatorAddress)/vault/\(vaultAddress)/rewards"
        case .prepareDepositTransaction:
            return "staking/deposit"
        case .prepareUnstakeTransaction:
            return "staking/unstake"
        case .prepareWithdrawTransaction:
            return "staking/withdraw"
        case .broadcastTransaction:
            return "transaction/send"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getVaultsList, .getAccountSummary, .getRewardsHistory:
            return .get
        case .prepareDepositTransaction, .prepareUnstakeTransaction, .prepareWithdrawTransaction, .broadcastTransaction:
            return .post
        }
    }

    var task: Task {
        switch target {
        case .getVaultsList, .getAccountSummary, .getRewardsHistory:
            return .requestPlain
        case .prepareDepositTransaction(let request):
            return .requestJSONEncodable(request)
        case .prepareUnstakeTransaction(let request):
            return .requestJSONEncodable(request)
        case .prepareWithdrawTransaction(let request):
            return .requestJSONEncodable(request)
        case .broadcastTransaction(let request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        [
            "Content-Type": "application/json",
            "authorization": "Bearer \(apiKey)",
        ]
    }
}

extension P2PTarget: TargetTypeLogConvertible {
    var requestDescription: String {
        path
    }

    var shouldLogResponseBody: Bool {
        switch target {
        case .getVaultsList, .getAccountSummary, .getRewardsHistory:
            return true
        default:
            return true // [REDACTED_TODO_COMMENT]
        }
    }
}
