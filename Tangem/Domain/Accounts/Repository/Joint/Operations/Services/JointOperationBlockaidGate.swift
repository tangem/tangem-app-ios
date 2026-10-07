//
//  JointOperationBlockaidGate.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import ReownWalletKit

protocol JointOperationBlockaidGate {
    func verdict(
        on operation: JointAccountOperation,
        safeAddress: String,
        ownerAddress: String?,
        blockchain: BlockchainSdk.Blockchain
    ) async -> JointOperationBlockaidVerdict
}

enum JointOperationBlockaidVerdict {
    case safe
    case malicious
    case unknown
    case unavailable
}

struct CommonJointOperationBlockaidGate: JointOperationBlockaidGate {
    private let apiService: BlockaidAPIService

    init(apiService: BlockaidAPIService = BlockaidFactory().makeBlockaidAPIService()) {
        self.apiService = apiService
    }

    func verdict(
        on operation: JointAccountOperation,
        safeAddress: String,
        ownerAddress: String?,
        blockchain: BlockchainSdk.Blockchain
    ) async -> JointOperationBlockaidVerdict {
        guard let ownerAddress else {
            JointAccountsLogger.warning("The owner address of a joint operation's co-signer could not be derived")
            return .unavailable
        }

        guard BlockaidDTO.Chain(blockchain: blockchain) != nil else {
            JointAccountsLogger.info("Blockaid does not support \(blockchain.displayName)")
            return .unknown
        }

        let typedData = operation.safeTransaction.typedData(chainId: operation.chainId, safeAddress: safeAddress)
        let response: BlockaidDTO.EvmScan.Response
        do {
            let typedDataJSON = String(decoding: try JSONEncoder().encode(typedData), as: UTF8.self)
            response = try await apiService.scanEvm(
                address: ownerAddress,
                blockchain: blockchain,
                method: Constants.method,
                params: [AnyCodable(ownerAddress), AnyCodable(typedDataJSON)],
                domain: Constants.domain
            )
        } catch {
            JointAccountsLogger.error("Blockaid could not scan a joint operation", error: error)
            return .unavailable
        }

        guard let validation = response.validation, validation.status == .success else {
            return .unknown
        }

        switch validation.resultType {
        case .malicious: return .malicious
        case .benign, .warning, .info: return .safe
        case .error: return .unknown
        }
    }
}

private extension CommonJointOperationBlockaidGate {
    enum Constants {
        static let method = "eth_signTypedData_v4"
        static let domain = URL(string: "https://tangem.com")!
    }
}
