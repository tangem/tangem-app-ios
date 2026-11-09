//
//  YieldModuleVersionResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// MARK: - Types

public enum YieldModuleUpgradeStatus: Equatable {
    case upToDate(version: YieldModuleVersion?)
    case upgradeAvailable(targetImplementation: String, targetVersion: YieldModuleVersion)
    case upgradeUnavailable(version: YieldModuleVersion?)

    public var effectiveVersion: YieldModuleVersion? {
        switch self {
        case .upToDate(let version), .upgradeUnavailable(let version):
            return version
        case .upgradeAvailable(_, let targetVersion):
            return targetVersion
        }
    }

    public func supports(_ minimumVersion: YieldModuleVersion) -> Bool {
        switch self {
        case .upToDate(nil):
            return true
        case .upgradeUnavailable(nil):
            return false
        case .upToDate(let version?), .upgradeUnavailable(let version?):
            return version >= minimumVersion
        case .upgradeAvailable(_, let targetVersion):
            return targetVersion >= minimumVersion
        }
    }
}

// MARK: - Protocol

public protocol YieldModuleVersionResolver {
    func resolveStatus(moduleAddress: String) async throws -> YieldModuleUpgradeStatus
}

protocol YieldModuleImplementationReader {
    func moduleImplementation(moduleAddress: String) async throws -> String
    func factoryImplementation() async throws -> String
}

// MARK: - Implementation

public final class CommonYieldModuleVersionResolver: YieldModuleVersionResolver {
    private let reader: YieldModuleImplementationReader
    private let blockchain: Blockchain
    private let dataStorage: BlockchainDataStorage
    private let factoryImplementationLifetime: TimeInterval
    private let now: () -> Date
    private let addressComparator = AddressComparator()
    private let cachedFactoryImplementation = OSAllocatedUnfairLock<CachedFactoryImplementation?>(initialState: nil)

    init(
        reader: YieldModuleImplementationReader,
        blockchain: Blockchain,
        dataStorage: BlockchainDataStorage,
        factoryImplementationLifetime: TimeInterval = Constants.factoryImplementationLifetime,
        now: @escaping () -> Date = Date.init
    ) {
        self.reader = reader
        self.blockchain = blockchain
        self.dataStorage = dataStorage
        self.factoryImplementationLifetime = factoryImplementationLifetime
        self.now = now
    }

    public func resolveStatus(moduleAddress: String) async throws -> YieldModuleUpgradeStatus {
        guard let latestVersion = YieldModuleImplementations.latestVersion(for: blockchain) else {
            return .upToDate(version: nil)
        }

        let storageKey = implementationStorageKey(moduleAddress: moduleAddress)

        if let storedImplementation: String = await dataStorage.get(key: storageKey),
           let storedStatus = upToDateStatus(moduleImplementation: storedImplementation, latestVersion: latestVersion) {
            return storedStatus
        }

        let module = try await reader.moduleImplementation(moduleAddress: moduleAddress)
        await dataStorage.store(key: storageKey, value: module)

        if let moduleStatus = upToDateStatus(moduleImplementation: module, latestVersion: latestVersion) {
            return moduleStatus
        }

        let factory = try await factoryImplementation()
        let resolvedStatus = status(moduleImplementation: module, factoryImplementation: factory.address)

        guard factory.isCached, case .upgradeAvailable = resolvedStatus else {
            return resolvedStatus
        }

        let freshFactory = try await readFactoryImplementation()
        return status(moduleImplementation: module, factoryImplementation: freshFactory)
    }
}

// MARK: - Private

private extension CommonYieldModuleVersionResolver {
    struct CachedFactoryImplementation: Sendable {
        let address: String
        let date: Date
    }

    func status(moduleImplementation: String, factoryImplementation: String) -> YieldModuleUpgradeStatus {
        let moduleVersion = version(ofImplementation: moduleImplementation)

        if addressComparator.addressesMatch(moduleImplementation, factoryImplementation, blockchain: blockchain) {
            return .upToDate(version: moduleVersion)
        }

        guard let factoryVersion = version(ofImplementation: factoryImplementation) else {
            return .upgradeUnavailable(version: moduleVersion)
        }

        guard let moduleVersion, moduleVersion >= factoryVersion else {
            return .upgradeAvailable(targetImplementation: factoryImplementation, targetVersion: factoryVersion)
        }

        return .upToDate(version: moduleVersion)
    }

    func upToDateStatus(moduleImplementation: String, latestVersion: YieldModuleVersion) -> YieldModuleUpgradeStatus? {
        let moduleVersion = version(ofImplementation: moduleImplementation)

        if moduleVersion == latestVersion {
            return .upToDate(version: latestVersion)
        }

        if let cachedFactory = validCachedFactoryImplementation(),
           addressComparator.addressesMatch(cachedFactory, moduleImplementation, blockchain: blockchain) {
            return .upToDate(version: moduleVersion)
        }

        return nil
    }

    func validCachedFactoryImplementation() -> String? {
        let cached = cachedFactoryImplementation.withLock { $0 }

        guard let cached, now().timeIntervalSince(cached.date) < factoryImplementationLifetime else {
            return nil
        }

        return cached.address
    }

    func factoryImplementation() async throws -> (address: String, isCached: Bool) {
        if let cached = validCachedFactoryImplementation() {
            return (cached, true)
        }

        return (try await readFactoryImplementation(), false)
    }

    func readFactoryImplementation() async throws -> String {
        let date = now()
        let address = try await reader.factoryImplementation()
        cachedFactoryImplementation.withLock { $0 = CachedFactoryImplementation(address: address, date: date) }
        return address
    }

    func version(ofImplementation address: String) -> YieldModuleVersion? {
        YieldModuleImplementations.version(ofImplementation: address, on: blockchain)
    }

    func implementationStorageKey(moduleAddress: String) -> String {
        let moduleAddressPart = Data(hex: moduleAddress).getSHA256().hexString
        return [
            moduleAddressPart,
            blockchain.coinId,
            Constants.yieldModuleImplementationStorageKey,
        ].joined(separator: "_")
    }
}

// MARK: - Constants

extension CommonYieldModuleVersionResolver {
    enum Constants {
        static let yieldModuleImplementationStorageKey = "yieldModuleResolvedImplementationStorageKey"
        static let factoryImplementationLifetime: TimeInterval = 600
    }
}

// MARK: - Reader

struct CommonYieldModuleImplementationReader: YieldModuleImplementationReader {
    let networkService: EthereumNetworkService
    let factoryContractAddress: String

    func moduleImplementation(moduleAddress: String) async throws -> String {
        let result = try await networkService
            .getStorageAt(address: moduleAddress, slot: Self.eip1967ImplementationSlot)
            .async()

        return try parseAddress(result)
    }

    func factoryImplementation() async throws -> String {
        let request = YieldSmartContractRequest(contractAddress: factoryContractAddress, method: FactoryImplementationMethod())
        let result = try await networkService.ethCall(request: request).async()

        return try parseAddress(result)
    }
}

private extension CommonYieldModuleImplementationReader {
    /// EIP-1967 implementation slot: `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    static let eip1967ImplementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

    func parseAddress(_ result: String) throws -> String {
        guard let address = YieldModuleUtils.parseEthereumAddress(result) else {
            throw YieldModuleError.unableToParseData
        }

        return address
    }
}
