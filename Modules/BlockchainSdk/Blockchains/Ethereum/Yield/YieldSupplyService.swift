//
//  YieldSupplyService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public protocol YieldSupplyService {
    func isSupported() -> Bool
    func getYieldSupplyContractAddresses() throws -> YieldSupplyContractAddresses
    func getYieldContract() async throws -> String

    func storeYieldContract(_ yieldContract: String) async
    func storedYieldContract() async -> String?

    func calculateYieldContract() async throws -> String
    func getYieldSupplyStatus(tokenContractAddress: String) async throws -> YieldSupplyStatus
    func getBalance(yieldSupplyStatus: YieldSupplyStatus, token: Token) async throws -> Amount
    func getBalances(address: String, tokens: [Token]) async -> [Token: Result<Amount, Error>]
    func allowance(tokenContractAddress: String) async throws -> String

    func makeVersionChecker() -> YieldModuleVersionChecker?
    func makeSwapExecutionRegistryProvider() -> YieldModuleSwapExecutionRegistryProvider?
}

public extension YieldSupplyService {
    func makeVersionChecker() -> YieldModuleVersionChecker? { nil }
    func makeSwapExecutionRegistryProvider() -> YieldModuleSwapExecutionRegistryProvider? { nil }
}

public protocol YieldModuleSwapExecutionRegistryProvider {
    func isAllowedSpender(_ spender: String) async throws -> Bool
    func isAllowedTarget(_ target: String) async throws -> Bool
}

public final class EthereumYieldSupplyService: YieldSupplyService {
    private let networkService: EthereumNetworkService
    private let wallet: Wallet
    private let contractAddressFactory: YieldSupplyContractAddressFactory
    private let dataStorage: BlockchainDataStorage

    init(
        networkService: EthereumNetworkService,
        wallet: Wallet,
        contractAddressFactory: YieldSupplyContractAddressFactory,
        dataStorage: BlockchainDataStorage,
    ) {
        self.networkService = networkService
        self.wallet = wallet
        self.contractAddressFactory = contractAddressFactory
        self.dataStorage = dataStorage
    }

    public func isSupported() -> Bool {
        contractAddressFactory.isSupported
    }

    public func getYieldSupplyContractAddresses() throws -> YieldSupplyContractAddresses {
        try contractAddressFactory.getYieldSupplyContractAddresses()
    }

    public func getYieldContract() async throws -> String {
        let storedYieldContractAddress = await storedYieldContract()
        switch storedYieldContractAddress {
        case .some(let address):
            return address
        case .none:
            let method = YieldModuleMethod(walletAddress: wallet.address)

            let request = YieldSmartContractRequest(
                contractAddress: try getYieldSupplyContractAddresses().factoryContractAddress,
                method: method
            )

            let result = try await networkService.ethCall(request: request).async()

            guard let yieldContract = YieldModuleUtils.parseEthereumAddress(result) else {
                throw YieldModuleError.noYieldContractFound
            }

            await dataStorage.store(key: storageKey(), value: yieldContract)

            return yieldContract
        }
    }

    public func storeYieldContract(_ yieldContract: String) async {
        await dataStorage.store(key: storageKey(), value: yieldContract)
    }

    public func storedYieldContract() async -> String? {
        await dataStorage.get(key: storageKey())
    }

    public func calculateYieldContract() async throws -> String {
        let method = CalculateYieldModuleAddressMethod(sourceAddress: wallet.address)

        let request = YieldSmartContractRequest(
            contractAddress: try getYieldSupplyContractAddresses().factoryContractAddress,
            method: method
        )

        let result = try await networkService.ethCall(request: request).async()

        guard let yieldContract = YieldModuleUtils.parseEthereumAddress(result) else {
            throw YieldModuleError.noYieldContractFound
        }

        return yieldContract
    }

    public func getYieldSupplyStatus(tokenContractAddress: String) async throws -> YieldSupplyStatus {
        let method = YieldSupplyStatusMethod(tokenContractAddress: tokenContractAddress)

        let request = try await YieldSmartContractRequest(
            contractAddress: getYieldContract(),
            method: method
        )

        let tokenData = try await networkService.ethCall(request: request).async()

        return try YieldResponseMapper.mapSupplyStatus(tokenData)
    }

    public func getBalance(yieldSupplyStatus: YieldSupplyStatus, token: Token) async throws -> Amount {
        async let allowance = allowance(tokenContractAddress: token.contractAddress)

        async let effectiveBalance = getEffectiveBalance(token: token)
        async let effectiveProtocolBalance = getEffectiveProtocolBalance(token: token)

        do {
            let (allowanceResult, effectiveBalanceResult, effectiveProtocolBalanceResult) = try await (
                allowance,
                effectiveBalance,
                effectiveProtocolBalance
            )

            return try await Amount(
                with: wallet.blockchain,
                type: .token(
                    value: token.withMetadata(
                        TokenMetadata(
                            kind: .fungible,
                            yieldSupply: TokenYieldSupply(
                                yieldContractAddress: getYieldContract(),
                                isActive: yieldSupplyStatus.active,
                                isInitialized: yieldSupplyStatus.initialized,
                                allowance: allowanceResult,
                                protocolBalanceValue: effectiveProtocolBalanceResult
                            )
                        )
                    )
                ),
                value: effectiveBalanceResult
            )
        } catch {
            throw YieldModuleError.unableToParseData
        }
    }

    public func getBalances(address: String, tokens: [Token]) async -> [Token: Result<Amount, any Error>] {
        guard isSupported() else {
            return [:]
        }

        return await withTaskGroup(of: (Token, Result<Amount, Error>?).self) { [weak self] group in
            for token in tokens {
                group.addTask {
                    do {
                        guard let self else { return (token, nil) }

                        guard let yieldLendingStatus = try? await self.getYieldSupplyStatus(
                            tokenContractAddress: token.contractAddress
                        ) else {
                            return (token, nil)
                        }

                        if yieldLendingStatus.active {
                            let balance = try await self.getBalance(
                                yieldSupplyStatus: yieldLendingStatus,
                                token: token
                            )
                            return (token, .success(balance))
                        } else {
                            return (token, nil)
                        }
                    } catch YieldModuleError.unsupportedBlockchain {
                        return (token, nil)
                    } catch {
                        return (token, .failure(error))
                    }
                }
            }

            var result = [Token: Result<Amount, Error>]()

            for await element in group {
                if let value = element.1 {
                    result[element.0] = value
                }
            }

            return result
        }
    }

    public func allowance(tokenContractAddress: String) async throws -> String {
        try await networkService.getAllowance(
            owner: wallet.address,
            spender: getYieldContract(),
            contractAddress: tokenContractAddress
        ).async()
    }

    public func makeVersionChecker() -> YieldModuleVersionChecker? {
        guard let factoryAddress = try? contractAddressFactory.getYieldSupplyContractAddresses().factoryContractAddress else {
            return nil
        }

        return CommonYieldModuleVersionChecker(
            networkService: networkService,
            blockchain: wallet.blockchain,
            walletAddress: wallet.defaultAddress.value,
            factoryContractAddress: factoryAddress,
            dataStorage: dataStorage
        )
    }

    public func makeSwapExecutionRegistryProvider() -> YieldModuleSwapExecutionRegistryProvider? {
        guard let registryAddress = try? contractAddressFactory.getYieldSupplyContractAddresses().swapExecutionRegistryContractAddress else {
            return nil
        }

        return CommonYieldModuleSwapExecutionRegistryProvider(
            networkService: networkService,
            registryAddress: registryAddress
        )
    }
}

private final class CommonYieldModuleSwapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider {
    private let networkService: EthereumNetworkService
    private let registryAddress: String

    init(networkService: EthereumNetworkService, registryAddress: String) {
        self.networkService = networkService
        self.registryAddress = registryAddress
    }

    func isAllowedSpender(_ spender: String) async throws -> Bool {
        try await isAllowed(method: AllowedSpenderMethod(spender: spender))
    }

    func isAllowedTarget(_ target: String) async throws -> Bool {
        try await isAllowed(method: AllowedTargetMethod(target: target))
    }

    private func isAllowed(method: SmartContractMethod) async throws -> Bool {
        let request = YieldSmartContractRequest(contractAddress: registryAddress, method: method)
        let result = try await networkService.ethCall(request: request).async()

        guard let value = BigUInt(result.removeHexPrefix(), radix: 16) else {
            throw YieldModuleError.unableToParseData
        }

        return value == 1
    }
}

private struct AllowedSpenderMethod {
    let spender: String
}

extension AllowedSpenderMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for `allowedSpenders(address)`.
    var methodId: String { "0xd8528af0" }
    var data: Data { defaultData() }
}

private struct AllowedTargetMethod {
    let target: String
}

extension AllowedTargetMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for `allowedTargets(address)`.
    var methodId: String { "0xb8fe8d5f" }
    var data: Data { defaultData() }
}

private extension EthereumYieldSupplyService {
    func getEffectiveBalance(token: Token) async throws -> Decimal {
        let method = EffectiveBalanceMethod(tokenContractAddress: token.contractAddress)

        return try await getBalance(method: method, decimalsCount: token.decimalCount)
    }

    func getEffectiveProtocolBalance(token: Token) async throws -> Decimal {
        let method = EffectiveProtocolBalanceMethod(tokenContractAddress: token.contractAddress)

        return try await getBalance(method: method, decimalsCount: token.decimalCount)
    }

    func getBalance(method: SmartContractMethod, decimalsCount: Int) async throws -> Decimal {
        async let request = YieldSmartContractRequest(
            contractAddress: getYieldContract(),
            method: method
        )

        let balance = try await networkService.ethCall(request: request).async()

        guard let result = EthereumUtils.parseEthereumDecimal(
            balance,
            decimalsCount: decimalsCount
        ) else {
            throw YieldModuleError.unableToParseData
        }

        return result
    }

    func storageKey() -> String {
        let walletAddressPart = Data(hex: wallet.defaultAddress.value).getSHA256().hexString
        return [
            walletAddressPart,
            wallet.blockchain.coinId,
            Constants.yieldContractAddressStorageKey,
        ].joined(separator: "_")
    }
}

extension EthereumYieldSupplyService {
    enum Constants {
        static let yieldContractAddressStorageKey = "yieldContractAddressStorageKey"
    }
}

private extension Token {
    func withMetadata(_ metadata: TokenMetadata) -> Self {
        Token(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: id,
            metadata: metadata
        )
    }
}
