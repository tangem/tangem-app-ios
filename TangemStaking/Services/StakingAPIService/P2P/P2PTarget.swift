//
//  P2PTarget.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

// MARK: - P2PTarget

enum P2PTarget {
    /// Get the list of vaults for a network
    case getVaultsList(network: String)
    /// Get account summary for a delegator in a vault
    case getAccountSummary(network: String, delegatorAddress: String, vaultAddress: String)
    /// Get rewards history for a delegator in a vault
    case getRewardsHistory(network: String, delegatorAddress: String, vaultAddress: String)
    /// Prepare deposit transaction
    case prepareDepositTransaction(network: String, request: P2PDTO.PrepareDepositTransaction.Request)
    /// Prepare unstake transaction
    case prepareUnstakeTransaction(network: String, request: P2PDTO.PrepareUnstakeTransaction.Request)
    /// Prepare withdraw transaction
    case prepareWithdrawTransaction(network: String, request: P2PDTO.PrepareWithdrawTransaction.Request)
    /// Broadcast a signed transaction
    case broadcastTransaction(network: String, request: P2PDTO.BroadcastTransaction.Request)
}

extension P2PTarget: TargetType {
    var baseURL: URL {
        // You may want to switch baseURL based on environment
        // For now, use production as default
        switch self {
        default:
            return URL(string: "https://api.p2p.org")!
        }
    }

    var path: String {
        switch self {
        case .getVaultsList(let network):
            return "/api/v1/staking/pool/\(network)/vaults"
        case .getAccountSummary(let network, let delegatorAddress, let vaultAddress):
            return "/api/v1/staking/pool/\(network)/account/\(delegatorAddress)/vault/\(vaultAddress)"
        case .getRewardsHistory(let network, let delegatorAddress, let vaultAddress):
            return "/api/v1/staking/pool/\(network)/account/\(delegatorAddress)/vault/\(vaultAddress)/rewards-history"
        case .prepareDepositTransaction(let network, _):
            return "/api/v1/staking/pool/\(network)/staking/deposit"
        case .prepareUnstakeTransaction(let network, _):
            return "/api/v1/staking/pool/\(network)/staking/unstake"
        case .prepareWithdrawTransaction(let network, _):
            return "/api/v1/staking/pool/\(network)/staking/withdraw"
        case .broadcastTransaction(let network, _):
            return "/api/v1/staking/pool/\(network)/staking/broadcast"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getVaultsList, .getAccountSummary, .getRewardsHistory:
            return .get
        case .prepareDepositTransaction, .prepareUnstakeTransaction, .prepareWithdrawTransaction, .broadcastTransaction:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .getVaultsList, .getAccountSummary, .getRewardsHistory:
            return .requestPlain
        case .prepareDepositTransaction(_, let request):
            return .requestJSONEncodable(request)
        case .prepareUnstakeTransaction(_, let request):
            return .requestJSONEncodable(request)
        case .prepareWithdrawTransaction(_, let request):
            return .requestJSONEncodable(request)
        case .broadcastTransaction(_, let request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }

    var sampleData: Data {
        Data()
    }
}
