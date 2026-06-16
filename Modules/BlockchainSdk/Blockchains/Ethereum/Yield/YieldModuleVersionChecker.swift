//
//  YieldModuleVersionChecker.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// MARK: - Types

public enum YieldModuleVersionStatus: Equatable {
    case upToDate
    case outdated(canUpgrade: Bool, latestImplementation: String?)
}

// MARK: - Protocol

public protocol YieldModuleVersionChecker {
    func checkVersion(userModuleAddress: String) async throws -> YieldModuleVersionStatus

    /// Re-fetches the on-chain implementation address and updates the local cache.
    /// Call after a successful `upgradeToAndCall` transaction.
    func refreshStoredVersion(userModuleAddress: String) async throws
}

// MARK: - Implementation

public final class CommonYieldModuleVersionChecker: YieldModuleVersionChecker {
    private let networkService: EthereumNetworkService
    private let blockchain: Blockchain
    private let walletAddress: String
    private let factoryContractAddress: String
    private let dataStorage: BlockchainDataStorage

    init(
        networkService: EthereumNetworkService,
        blockchain: Blockchain,
        walletAddress: String,
        factoryContractAddress: String,
        dataStorage: BlockchainDataStorage
    ) {
        self.networkService = networkService
        self.blockchain = blockchain
        self.walletAddress = walletAddress
        self.factoryContractAddress = factoryContractAddress
        self.dataStorage = dataStorage
    }

    public func checkVersion(userModuleAddress: String) async throws -> YieldModuleVersionStatus {
        guard let knownLatest = YieldModuleImplementationAddresses.latestImplementation(for: blockchain) else {
            return .upToDate
        }

        // 1. Check cached version first
        let storedImpl: String? = await dataStorage.get(key: implementationStorageKey())
        if let storedImpl, storedImpl.caseInsensitiveEquals(to: knownLatest) {
            return .upToDate
        }

        // 2. Read on-chain implementation via EIP-1967 proxy storage slot
        let onChainImpl = try await fetchOnChainImplementation(userModuleAddress: userModuleAddress)
        await dataStorage.store(key: implementationStorageKey(), value: onChainImpl)

        // 3. Compare with known latest
        if onChainImpl.caseInsensitiveEquals(to: knownLatest) {
            return .upToDate
        }

        // 4. Module is outdated — verify the factory's implementation matches our hardcoded latest
        let factoryImpl = try await fetchFactoryImplementation()

        if factoryImpl.caseInsensitiveEquals(to: knownLatest) {
            return .outdated(canUpgrade: true, latestImplementation: knownLatest)
        } else {
            return .outdated(canUpgrade: false, latestImplementation: nil)
        }
    }

    public func refreshStoredVersion(userModuleAddress: String) async throws {
        let onChainImpl = try await fetchOnChainImplementation(userModuleAddress: userModuleAddress)
        await dataStorage.store(key: implementationStorageKey(), value: onChainImpl)
    }
}

// MARK: - Private

private extension CommonYieldModuleVersionChecker {
    /// EIP-1967 implementation slot: `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    static let eip1967ImplementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

    func fetchOnChainImplementation(userModuleAddress: String) async throws -> String {
        let result = try await networkService
            .getStorageAt(address: userModuleAddress, slot: Self.eip1967ImplementationSlot)
            .async()

        guard let address = YieldModuleUtils.parseEthereumAddress(result) else {
            throw YieldModuleError.unableToParseData
        }

        return address
    }

    func fetchFactoryImplementation() async throws -> String {
        let method = FactoryImplementationMethod()
        let request = YieldSmartContractRequest(contractAddress: factoryContractAddress, method: method)
        let result = try await networkService.ethCall(request: request).async()

        guard let address = YieldModuleUtils.parseEthereumAddress(result) else {
            throw YieldModuleError.unableToParseData
        }

        return address
    }

    func implementationStorageKey() -> String {
        let walletAddressPart = Data(hex: walletAddress).getSHA256().hexString
        return [
            walletAddressPart,
            blockchain.coinId,
            Constants.yieldModuleImplementationStorageKey,
        ].joined(separator: "_")
    }

    enum Constants {
        static let yieldModuleImplementationStorageKey = "yieldModuleImplementationStorageKey"
    }
}
