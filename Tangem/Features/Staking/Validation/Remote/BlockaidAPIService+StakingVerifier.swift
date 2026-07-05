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

extension CommonBlockaidAPIService: StakingTransactionVerifier {
    func verify(
        network: RemoteValidationNetwork,
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
            throw RemoteStakingValidationError.validationFailed(description: "Malformed EVM transaction payload")
        }

        let txParams: BlockaidDTO.TransactionParams
        do {
            let decoded = try JSONDecoder().decode(EthereumCompiledTransactionData.self, from: jsonData)
            txParams = decoded.toBlockaidParams()
        } catch {
            throw RemoteStakingValidationError.validationFailed(description: "Failed to decode EVM transaction: \(error.localizedDescription)")
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
            throw RemoteStakingValidationError.validationFailed(
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
            throw RemoteStakingValidationError.validationFailed(description: "Malformed Solana transaction payload")
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
            throw RemoteStakingValidationError.validationFailed(
                description: "Network error: \(error.localizedDescription)"
            )
        }

        try validateSolanaResponse(response)
    }

    func validateEvmResponse(_ response: BlockaidDTO.EvmScan.Response) throws {
        if response.simulation?.status != .success {
            let errorDescription = response.validation?.error ?? "Simulation failed"
            throw RemoteStakingValidationError.validationFailed(description: errorDescription)
        }

        guard let validation = response.validation else {
            throw RemoteStakingValidationError.validationFailed(description: "Missing validation result")
        }

        try checkValidationResult(validation)
    }

    func validateSolanaResponse(_ response: BlockaidDTO.SolanaScan.Response) throws {
        guard let validation = response.result.validation else {
            throw RemoteStakingValidationError.validationFailed(description: "Missing validation result")
        }

        try checkValidationResult(validation)
    }

    func checkValidationResult(_ validation: BlockaidDTO.Validation) throws {
        switch validation.resultType {
        case .benign:
            return

        case .warning:
            throw RemoteStakingValidationError.warning(
                description: validation.description ?? "Transaction flagged as potentially dangerous"
            )

        case .malicious:
            throw RemoteStakingValidationError.malicious(
                description: validation.description ?? "Transaction flagged as malicious"
            )

        case .error:
            throw RemoteStakingValidationError.validationFailed(
                description: validation.error ?? "Validation error"
            )

        case .info:
            return
        }
    }
}

private extension EthereumCompiledTransactionData {
    func toBlockaidParams() -> BlockaidDTO.TransactionParams {
        BlockaidDTO.TransactionParams(
            from: from,
            to: to,
            data: data,
            value: value ?? "0x0"
        )
    }
}
