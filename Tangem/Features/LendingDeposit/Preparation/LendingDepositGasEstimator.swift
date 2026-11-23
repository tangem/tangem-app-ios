//
//  LendingDepositGasEstimator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

protocol LendingDepositGasEstimating {
    func gas(preparation: TransferPreparationCall, deposit: TransferPreparationCall) async -> TransferPreparationGas?
}

struct LendingDepositGasEstimator: LendingDepositGasEstimating {
    let owner: String
    let blockchain: Blockchain
    let simulator: LendingDepositGasSimulating
    let allowsFallback: Bool

    func gas(preparation: TransferPreparationCall, deposit: TransferPreparationCall) async -> TransferPreparationGas? {
        do {
            let simulations = try await simulator.simulate([try params(preparation), try params(deposit)], on: blockchain)

            guard !simulations.contains(.reverted) else {
                AppLogger.info("Lending deposit simulation reverted, the deposit can't be sent")
                return nil
            }

            let limits = simulations
                .compactMap { simulation -> BigUInt? in
                    guard case .estimated(let estimate?) = simulation else { return nil }
                    return EthereumUtils.sanitizeAndParseToBigUInt(estimate)
                }
                .map(Self.withMargin)

            guard limits.count == 2,
                  limits.allSatisfy({ $0 > 0 }),
                  let preparationGas = Int(exactly: limits[0]),
                  let depositGas = Int(exactly: limits[1]) else {
                return fallback
            }

            return TransferPreparationGas(preparation: preparationGas, mainCall: depositGas)
        } catch {
            guard !Task.isCancelled else {
                return nil
            }

            AppLogger.error("Lending deposit gas simulation failed", error: error)
            return fallback
        }
    }
}

// MARK: - Private

private extension LendingDepositGasEstimator {
    var fallback: TransferPreparationGas? {
        guard allowsFallback, let limit = Int(exactly: Self.withMargin(BigUInt(Constants.fallbackGasLimit))) else {
            return nil
        }

        return TransferPreparationGas(preparation: limit, mainCall: limit)
    }

    static func withMargin(_ limit: BigUInt) -> BigUInt {
        limit + limit * EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent / 100
    }

    func params(_ call: TransferPreparationCall) throws -> BlockaidDTO.TransactionParams {
        guard let value = Amount(with: blockchain, type: .coin, value: call.value).encodedForSend else {
            throw EstimationError.valueNotEncodable
        }

        return BlockaidDTO.TransactionParams(
            from: owner,
            to: call.destination,
            data: call.data.hexString.addHexPrefix(),
            value: value
        )
    }

    enum EstimationError: Error {
        case valueNotEncodable
    }

    enum Constants {
        static let fallbackGasLimit = 500_000
    }
}
