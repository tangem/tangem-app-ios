//
//  BlockaidAPIService+StakingVerifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import ReownWalletKit
import TangemFoundation

private enum StakingBlockaidConstants {
    static let stakingDomain = URL(string: "https://tangem.com")!
}

extension CommonBlockaidAPIService: BlockAidStakingVerifier {
    func verify(
        network: BlockAidSupportedNetwork,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws {
        switch network {
        case .evm(let blockchain):
            try await verifyEvmStakingTransaction(
                blockchain: blockchain,
                accountAddress: accountAddress,
                unsignedTransaction: unsignedTransaction
            )

        case .solana:
            try await verifySolanaStakingTransaction(
                accountAddress: accountAddress,
                unsignedTransaction: unsignedTransaction
            )
        }
    }
}

private extension CommonBlockaidAPIService {
    func verifyEvmStakingTransaction(
        blockchain: BlockchainSdk.Blockchain,
        accountAddress: String,
        unsignedTransaction: String
    ) async throws {
        guard let jsonData = unsignedTransaction.data(using: .utf8) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let txParams: [String: AnyCodable]
        do {
            let decoded = try JSONDecoder().decode(EthereumCompiledTransactionData.self, from: jsonData)
            txParams = decoded.toBlockaidParams()
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let response: BlockaidDTO.EvmScan.Response
        do {
            response = try await scanEvm(
                address: accountAddress,
                blockchain: blockchain,
                method: "eth_sendTransaction",
                params: [AnyCodable(txParams)],
                domain: StakingBlockaidConstants.stakingDomain
            )
        } catch {
            throw StakingTransactionValidationError.blockaidValidationFailed(
                description: "Network error: \(error.localizedDescription)"
            )
        }

        try validateEvmResponse(response)
    }

    func verifySolanaStakingTransaction(
        accountAddress: String,
        unsignedTransaction: String
    ) async throws {
        let txData = Data(hex: unsignedTransaction)
        guard !txData.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let base64Transaction = txData.base64EncodedString()

        let response: BlockaidDTO.SolanaScan.Response
        do {
            response = try await scanSolana(
                address: accountAddress.base58DecodedData.base64EncodedString(),
                method: "signTransaction",
                transactions: [base64Transaction],
                domain: StakingBlockaidConstants.stakingDomain
            )
        } catch {
            throw StakingTransactionValidationError.blockaidValidationFailed(
                description: "Network error: \(error.localizedDescription)"
            )
        }

        try validateSolanaResponse(response)
    }

    func validateEvmResponse(_ response: BlockaidDTO.EvmScan.Response) throws {
        if response.simulation?.status != .success {
            let errorDescription = response.validation?.error ?? "Simulation failed"
            throw StakingTransactionValidationError.blockaidValidationFailed(description: errorDescription)
        }

        guard let validation = response.validation else {
            throw StakingTransactionValidationError.blockaidValidationFailed(description: "Missing validation result")
        }

        try checkValidationResult(validation)
    }

    func validateSolanaResponse(_ response: BlockaidDTO.SolanaScan.Response) throws {
        guard let validation = response.result.validation else {
            throw StakingTransactionValidationError.blockaidValidationFailed(description: "Missing validation result")
        }

        try checkValidationResult(validation)
    }

    func checkValidationResult(_ validation: BlockaidDTO.Validation) throws {
        switch validation.resultType {
        case .benign:
            return

        case .warning:
            throw StakingTransactionValidationError.blockaidWarning(
                description: validation.description ?? "Transaction flagged as potentially dangerous"
            )

        case .malicious:
            throw StakingTransactionValidationError.blockaidMalicious(
                description: validation.description ?? "Transaction flagged as malicious"
            )

        case .error:
            throw StakingTransactionValidationError.blockaidValidationFailed(
                description: validation.error ?? "Validation error"
            )

        case .info:
            return
        }
    }
}

private extension EthereumCompiledTransactionData {
    func toBlockaidParams() -> [String: AnyCodable] {
        var params: [String: AnyCodable] = [
            "from": AnyCodable(from),
            "to": AnyCodable(to),
            "data": AnyCodable(data),
        ]

        if let value {
            params["value"] = AnyCodable(value)
        }

        return params
    }
}
