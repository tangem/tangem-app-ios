//
//  LendingDepositGasSimulator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Moya
import TangemFoundation
import TangemNetworkUtils

protocol LendingDepositGasSimulating {
    func simulate(_ transactions: [BlockaidDTO.TransactionParams], on blockchain: Blockchain) async throws -> [LendingDepositGasSimulation]
}

enum LendingDepositGasSimulation: Equatable {
    case estimated(String?)
    case reverted
}

struct BlockaidLendingDepositGasSimulator: LendingDepositGasSimulating {
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let provider = TangemProvider<BlockaidTarget>(
        configuration: TangemProviderConfiguration(
            logOptions: .verbose,
            urlSessionConfiguration: .ephemeralConfiguration
        )
    )

    func simulate(_ transactions: [BlockaidDTO.TransactionParams], on blockchain: Blockchain) async throws -> [LendingDepositGasSimulation] {
        guard let chain = BlockaidDTO.Chain(blockchain: blockchain) else {
            throw CommonBlockaidAPIService.BlockaidAPIServiceError.blockchainIsNotSupported
        }

        let request = BlockaidDTO.EvmTransactionBulkScan.Request(
            chain: chain,
            data: transactions.map {
                BlockaidDTO.EvmTransactionBulkScan.Request.Data(from: $0.from, to: $0.to, value: $0.value, data: $0.data)
            },
            aggregated: false
        )

        let response = try await provider
            .requestPublisher(BlockaidTarget(apiKey: keysManager.blockaidAPIKey, target: .scanEvmTransactionBulk(request: request)))
            .async()
            .filterSuccessfulStatusAndRedirectCodes()

        return try Self.simulations(from: response.data)
    }

    static func simulations(from data: Data) throws -> [LendingDepositGasSimulation] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode([Element].self, from: data).map { element in
            element.gasEstimation.status == Constants.errorStatus ? .reverted : .estimated(element.gasEstimation.estimate)
        }
    }
}

// MARK: - Private

private extension BlockaidLendingDepositGasSimulator {
    struct Element: Decodable {
        let gasEstimation: GasEstimation

        struct GasEstimation: Decodable {
            let status: String
            let estimate: String?
        }
    }

    enum Constants {
        static let errorStatus = "Error"
    }
}
