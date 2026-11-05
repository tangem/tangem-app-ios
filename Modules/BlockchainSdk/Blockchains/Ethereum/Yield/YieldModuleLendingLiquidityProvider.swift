//
//  YieldModuleLendingLiquidityProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol YieldModuleLendingLiquidityProvider {
    func wrappedNative() async throws -> String
    func nativePosition() async throws -> Decimal
    func availableToWithdraw(nativePosition: Decimal) async throws -> Decimal
}

final class CommonYieldModuleLendingLiquidityProvider: YieldModuleLendingLiquidityProvider {
    private let smartContractInteractor: EVMSmartContractInteractor
    private let decimalCount: Int
    private let resolveYieldModule: () async throws -> String

    init(
        smartContractInteractor: EVMSmartContractInteractor,
        decimalCount: Int,
        resolveYieldModule: @escaping () async throws -> String
    ) {
        self.smartContractInteractor = smartContractInteractor
        self.decimalCount = decimalCount
        self.resolveYieldModule = resolveYieldModule
    }

    func wrappedNative() async throws -> String {
        try await address(returnedBy: WrappedNativeMethod(), contract: resolveYieldModule())
    }

    func nativePosition() async throws -> Decimal {
        let yieldModule = try await resolveYieldModule()
        let wrappedNative = try await address(returnedBy: WrappedNativeMethod(), contract: yieldModule)
        let result = try await call(EffectiveProtocolBalanceMethod(tokenContractAddress: wrappedNative), contract: yieldModule)

        return try amount(from: result)
    }

    func availableToWithdraw(nativePosition: Decimal) async throws -> Decimal {
        try await min(nativePosition, liquidity())
    }

    private func liquidity() async throws -> Decimal {
        let yieldModule = try await resolveYieldModule()

        async let pool = address(returnedBy: YieldModulePoolMethod(), contract: yieldModule)
        async let wrappedNative = address(returnedBy: WrappedNativeMethod(), contract: yieldModule)

        let method = try await VirtualUnderlyingBalanceMethod(assetContractAddress: wrappedNative)
        let result = try await call(method, contract: pool)

        return try amount(from: result)
    }

    private func amount(from result: String) throws -> Decimal {
        guard result.removeHexPrefix().count == Constants.wordHexLength,
              let amount = EthereumUtils.parseEthereumDecimal(result, decimalsCount: decimalCount) else {
            throw YieldModuleError.unableToParseData
        }

        return amount
    }

    private func address(returnedBy method: SmartContractMethod, contract: String) async throws -> String {
        guard let address = try await YieldModuleUtils.parseEthereumAddress(call(method, contract: contract)) else {
            throw YieldModuleError.unableToParseData
        }

        return address
    }

    private func call(_ method: SmartContractMethod, contract: String) async throws -> String {
        let request = YieldSmartContractRequest(contractAddress: contract, method: method)

        return try await smartContractInteractor.ethCall(request: request).async()
    }
}

private extension CommonYieldModuleLendingLiquidityProvider {
    enum Constants {
        static let wordHexLength = 64
    }
}
