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
    func getYieldBalanceInfo(for address: String, contractAddress: String) async throws -> YieldBalanceInfo
}

public final class CommonYieldTokenService: YieldTokenService {
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    init(evmSmartContractInteractor: EVMSmartContractInteractor) {
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

        let supplyAPYPercent = try YieldServiceAPYConverter.convert(supplyAPYData)
        let serviceFeeRate = try YieldServiceFeeRateConverter.convert(serviceFeeRateData)

        return supplyAPYPercent * (1 - serviceFeeRate)
    }

    public func getYieldBalanceInfo(for address: String, contractAddress: String) async throws -> YieldBalanceInfo {
        let yieldModuleAddress = try await getYieldModule(for: address)

        if let yieldModuleAddress {
            let yieldTokenData = try await getYieldTokenData(for: yieldModuleAddress, contractAddress: contractAddress)

            let maxNetworkFee = yieldTokenData.maxNetworkFee

            if yieldTokenData.initialized {
                if yieldTokenData.active {
                    let balance = try await getYieldBalances(for: yieldModuleAddress, contractAddress: contractAddress)
                    return YieldBalanceInfo(state: .initialized(state: .active(balance), maxNetworkFee: maxNetworkFee))
                } else {
                    return YieldBalanceInfo(state: .initialized(state: .notActive, maxNetworkFee: maxNetworkFee))
                }
            } else {
                return YieldBalanceInfo(state: .notInitialized(yieldToken: yieldModuleAddress))
            }
        } else {
            return YieldBalanceInfo(state: .notInitialized(yieldToken: nil))
        }
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

        return try YieldServiceYieldTokenDataConverter.convert(tokenData)
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

        async let effectiveBalanceRequest = evmSmartContractInteractor.ethCall(request: effectiveRequest).async()
        async let protocolBalanceRequest = evmSmartContractInteractor.ethCall(request: protocolRequest).async()

        let (effectiveBalanceData, protocolBalanceData) = try await (effectiveBalanceRequest, protocolBalanceRequest)

        let effectiveBalance = BigUInt(Data(hexString: effectiveBalanceData))
        let protocolBalance = BigUInt(Data(hexString: protocolBalanceData))

        return YieldBalances(
            effective: effectiveBalance,
            protocol: protocolBalance
        )
    }
}
