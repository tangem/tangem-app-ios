//
//  YieldSupplyService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BigInt

public protocol YieldSupplyService {
    func isSupported() -> Bool
    func getYieldSupplyContractAddresses() throws -> YieldSupplyContractAddresses
    func getAPY(for contractAddress: String) async throws -> Decimal
    func getYieldContract() async throws -> String
    func calculateYieldContract() async throws -> String
    func getYieldSupplyStatus(tokenContractAddress: String) async throws -> YieldSupplyStatus
    func getBalance(yieldSupplyStatus: YieldSupplyStatus, token: Token) async throws -> Amount
    func getProtocolBalance(token: Token) async throws -> Decimal
    func allowance(tokenContractAddress: String) async throws -> Decimal
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

    public func getAPY(for contractAddress: String) async throws -> Decimal {
        let supplyContractAddresses = try getYieldSupplyContractAddresses()

        let supplyAPYMethod = ReserveDataAaveV3Method(contractAddress: contractAddress)

        let supplyAPYRequest = YieldSmartContractRequest(
            contractAddress: supplyContractAddresses.poolContractAddress,
            method: supplyAPYMethod
        )

        async let supplyAPYResult = networkService.ethCall(request: supplyAPYRequest).async()

        let serviceFeeRateMethod = ServiceFeeRateMethod()

        let serviceFeeRateRequest = YieldSmartContractRequest(
            contractAddress: supplyContractAddresses.processorContractAddress,
            method: serviceFeeRateMethod
        )

        async let serviceFeeRateResult = networkService.ethCall(
            request: serviceFeeRateRequest
        ).async()

        let (supplyAPYData, serviceFeeRateData) = try await (supplyAPYResult, serviceFeeRateResult)

        let supplyAPYPercent = try YieldResponseMapper.mapAPY(supplyAPYData)
        let serviceFeeRate = try YieldResponseMapper.mapFeeRate(serviceFeeRateData)

        return supplyAPYPercent * (1 - serviceFeeRate)
    }

    public func getYieldContract() async throws -> String {
        let storageKey = [
            wallet.defaultAddress.value,
            wallet.blockchain.coinId,
            Constants.yieldContractAddressStorageKey,
        ].joined(separator: "_")

        let storedYieldContractAddress: String? = await dataStorage.get(key: storageKey)
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

            let resultNoHex = result.removeHexPrefix()
            if resultNoHex.isEmpty || BigUInt(resultNoHex) == 0 {
                throw YieldModuleError.unableToParseData
            }

            let contractAddress = resultNoHex.stripLeadingZeroes().addHexPrefix()

            await dataStorage.store(key: storageKey, value: contractAddress)

            return contractAddress
        }
    }

    public func calculateYieldContract() async throws -> String {
        let method = CalculateYieldModuleAddressMethod(sourceAddress: wallet.address)

        let request = YieldSmartContractRequest(
            contractAddress: try getYieldSupplyContractAddresses().factoryContractAddress,
            method: method
        )

        let result = try await networkService.ethCall(request: request).async()

        let resultNoHex = result.removeHexPrefix()

        return resultNoHex.stripLeadingZeroes().addHexPrefix()
    }

    public func getYieldSupplyStatus(tokenContractAddress: String) async throws -> YieldSupplyStatus {
        let method = YieldSupplyStatusMethod(tokenContractAddress: tokenContractAddress)

        async let request = YieldSmartContractRequest(
            contractAddress: getYieldContract(),
            method: method
        )

        let tokenData = try await networkService.ethCall(request: request).async()

        return try YieldResponseMapper.mapSupplyStatus(tokenData)
    }

    public func getBalance(yieldSupplyStatus: YieldSupplyStatus, token: Token) async throws -> Amount {
        let effectiveMethod = EffectiveBalanceMethod(tokenContractAddress: token.contractAddress)

        async let yieldContract = getYieldContract()

        let effectiveRequest = try await YieldSmartContractRequest(
            contractAddress: yieldContract,
            method: effectiveMethod
        )

        async let allowance = allowance(tokenContractAddress: token.contractAddress)
        async let effectiveBalance = networkService.ethCall(request: effectiveRequest).async()

        do {
            let (allowanceResult, effectiveBalanceResult) = try await (allowance, effectiveBalance)
            guard let result = EthereumUtils.parseEthereumDecimal(
                effectiveBalanceResult,
                decimalsCount: wallet.blockchain.decimalCount
            ) else {
                throw YieldModuleError.unableToParseData
            }

            return Amount(
                with: wallet.blockchain,
                type: .token(
                    value: token.withMetadata(
                        TokenMetadata(
                            kind: .yield(
                                supplyInfo: TokenYieldSupply(
                                    yieldContractAddress: try await yieldContract,
                                    isActive: yieldSupplyStatus.active,
                                    isInitialized: yieldSupplyStatus.initialized,
                                    allowance: allowanceResult
                                )
                            )
                        )
                    )
                ),
                value: result
            )
        } catch {
            throw YieldModuleError.unableToParseData
        }
    }

    public func getProtocolBalance(token: Token) async throws -> Decimal {
        let method = ProtocolBalanceMethod(tokenContractAddress: token.contractAddress)

        async let request = YieldSmartContractRequest(
            contractAddress: getYieldContract(),
            method: method
        )

        let protocolBalance = try await networkService.ethCall(request: request).async()

        guard let result = EthereumUtils.parseEthereumDecimal(
            protocolBalance,
            decimalsCount: wallet.blockchain.decimalCount
        ) else {
            throw YieldModuleError.unableToParseData
        }

        return result
    }

    public func allowance(tokenContractAddress: String) async throws -> Decimal {
        let allowance = try await networkService.getAllowance(
            owner: wallet.address,
            spender: getYieldContract(),
            contractAddress: tokenContractAddress
        ).async()

        guard let result = EthereumUtils.parseEthereumDecimal(
            allowance,
            decimalsCount: wallet.blockchain.decimalCount
        ) else {
            throw YieldModuleError.unableToParseData
        }

        return result
    }
}

extension EthereumYieldSupplyService {
    enum Constants {
        static let yieldContractAddressStorageKey = "yieldContractAddressStorageKey"
    }
}
