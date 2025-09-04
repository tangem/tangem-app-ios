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
    func getYieldBalances(for yieldToken: String, contractAddress: String) async throws -> YieldBalances
}

public final class CommonYieldTokenService: YieldTokenService {
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    public init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    public func getAPY(for contractAddress: String) async throws -> Decimal {
        let supplyAPYMethod = ReservedDataMethod(contractAddress: contractAddress)

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

            if yieldTokenData.initialized {
                if yieldTokenData.active {
                    let activeStateInfo = YieldTokenState.ActiveStateInfo(
                        yieldToken: yieldToken,
                        maxNetworkFee: maxNetworkFee
                    )
                    return .initialized(activeState: .active(activeStateInfo))
                } else {
                    return .initialized(activeState: .notActive)
                }
            } else {
                return .notInitialized(yieldToken: yieldToken)
            }
        } else {
            return .notDeployed
        }
    }

    public func getYieldBalances(for yieldToken: String, contractAddress: String) async throws -> YieldBalances {
        let effectiveMethod = EffectiveBalanceMethod(yieldTokenAddress: contractAddress)

        let effectiveRequest = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: effectiveMethod
        )

        let protocolMethod = ProtocolBalanceMethod(yieldTokenAddress: contractAddress)

        let protocolRequest = YieldSmartContractRequest(
            contractAddress: yieldToken,
            method: protocolMethod
        )

        async let effectiveBalance = evmSmartContractInteractor.ethCall(request: effectiveRequest).async()
        async let protocolBalance = evmSmartContractInteractor.ethCall(request: protocolRequest).async()

        return try await YieldResponseMapper.mapBalances(
            protocolBalance: effectiveBalance,
            effectiveBalance: effectiveBalance
        )
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
