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
    func getYieldContract() async throws -> String
    func calculateYieldContract() async throws -> String
    func getYieldSupplyStatus(tokenContractAddress: String) async throws -> YieldSupplyStatus
    func getBalance(yieldSupplyStatus: YieldSupplyStatus, token: Token) async throws -> Amount
    func getBalances(address: String, tokens: [Token]) async -> [Token: Result<Amount, Error>]
    func getProtocolBalance(token: Token) async throws -> Decimal
    func allowance(tokenContractAddress: String) async throws -> String
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
        let walletAddressPart = Data(hex: wallet.defaultAddress.value).getSha256().hexString

        let storageKey = [
            walletAddressPart,
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
                throw YieldModuleError.noYieldContractFound
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

        let request = try await YieldSmartContractRequest(
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
                decimalsCount: token.decimalCount
            ) else {
                throw YieldModuleError.unableToParseData
            }

            return Amount(
                with: wallet.blockchain,
                type: .token(
                    value: token.withMetadata(
                        TokenMetadata(
                            kind: .fungible,
                            yieldSupply: TokenYieldSupply(
                                yieldContractAddress: try await yieldContract,
                                isActive: yieldSupplyStatus.active,
                                isInitialized: yieldSupplyStatus.initialized,
                                allowance: allowanceResult
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

    public func allowance(tokenContractAddress: String) async throws -> String {
        try await networkService.getAllowance(
            owner: wallet.address,
            spender: getYieldContract(),
            contractAddress: tokenContractAddress
        ).async()
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
