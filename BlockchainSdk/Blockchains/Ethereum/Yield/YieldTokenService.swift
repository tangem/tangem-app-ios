//
//  YieldTokenService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public protocol YieldTokenService {
    func getAPY(for contractAddress: String) async throws -> Decimal
    func getYieldTokenState(for address: String, contractAddress: String) async throws -> YieldTokenState
    func getYieldBalance(for yieldToken: String, contractAddress: String) async throws -> Decimal
}

public final class CommonYieldTokenService: YieldTokenService {
    private let blockchain: Blockchain
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    public init(blockchain: Blockchain, evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.blockchain = blockchain
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    public func getAPY(for contractAddress: String) async throws -> Decimal {
        let supplyAPYMethod = ReserveDataAaveV3Method(contractAddress: contractAddress)

        let supplyAPYRequest = YieldSmartContractRequest(
            contractAddress: YieldConstants.aavePoolContractAddress,
            method: supplyAPYMethod
        )

        async let supplyAPYResult = evmSmartContractInteractor.ethCall(request: supplyAPYRequest).async()

        let serviceFeeRateMethod = ServiceFeeRateMethod()

        let serviceFeeRateRequest = YieldSmartContractRequest(
            contractAddress: YieldConstants.yieldProcessorContractAddress,
            method: serviceFeeRateMethod
        )

        async let serviceFeeRateResult = evmSmartContractInteractor.ethCall(
            request: serviceFeeRateRequest
        ).async()

        let (supplyAPYData, serviceFeeRateData) = try await (supplyAPYResult, serviceFeeRateResult)

        let supplyAPYPercent = try YieldResponseMapper.mapAPY(supplyAPYData)
        let serviceFeeRate = try YieldResponseMapper.mapFeeRate(serviceFeeRateData)

        return supplyAPYPercent * (1 - serviceFeeRate)
    }

    public func getYieldTokenState(for address: String, contractAddress: String) async throws -> YieldTokenState {
        let yieldToken = try await getYieldModule(for: address)

        if let yieldToken {
            let yieldTokenData = try await getYieldTokenData(for: yieldToken, contractAddress: contractAddress)

            let maxNetworkFee = yieldTokenData.maxNetworkFee

            let initializationState: YieldTokenState.InitializationState = if yieldTokenData.initialized {
                if yieldTokenData.active {
                    .initialized(activeState: .active(maxNetworkFee: maxNetworkFee))
                } else {
                    .initialized(activeState: .notActive)
                }
            } else {
                .notInitialized
            }
            return .deployed(.init(yieldToken: yieldToken, initializationState: initializationState))
        } else {
            return .notDeployed
        }
    }

    public func getYieldBalance(for yieldToken: String, contractAddress: String) async throws -> Decimal {
        let effectiveMethod = EffectiveBalanceMethod(yieldTokenAddress: contractAddress)

        let effectiveRequest = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: effectiveMethod
        )

        let effectiveBalance = try await evmSmartContractInteractor.ethCall(request: effectiveRequest).async()
        guard let result = EthereumUtils.parseEthereumDecimal(
            effectiveBalance,
            decimalsCount: blockchain.decimalCount
        ) else {
            throw YieldServiceError.unableToParseData
        }

        return result
    }

    private func getYieldModule(for address: String) async throws -> String? {
        let method = YieldModuleMethod(address: address)

        let request = YieldSmartContractRequest(
            contractAddress: YieldConstants.yieldModuleFactoryContractAddress,
            method: method
        )

        let result = try await evmSmartContractInteractor.ethCall(request: request).async()

        let resultNoHex = result.removeHexPrefix()
        if resultNoHex.isEmpty || BigUInt(resultNoHex) == 0 {
            return nil
        }

        return resultNoHex.stripLeadingZeroes().addHexPrefix()
    }

    private func getYieldTokenData(for yieldToken: String, contractAddress: String) async throws -> YieldTokenData {
        let method = YieldTokenDataMethod(contractAddress: contractAddress)

        let request = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: method
        )

        let tokenData = try await evmSmartContractInteractor.ethCall(request: request).async()

        return try YieldResponseMapper.mapTokenData(tokenData)
    }
}
