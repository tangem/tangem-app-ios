//
//  BaseWalletManagerUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// MARK: - BaseWalletManagerUpdater

public protocol BaseWalletManagerUpdater: AnyObject {
    func updateWalletManager(address: any Address) async throws
    func updateWalletManager(address: String) async throws
}

// MARK: - BaseWalletManagerUpdater + String

public extension BaseWalletManagerUpdater {
    func updateWalletManager(address: any Address) async throws {
        try await updateWalletManager(address: address.value)
    }
}

// MARK: - BaseWalletManagerUpdater + MultiAddressesWalletManagerUpdater

public extension BaseWalletManagerUpdater where Self: MultiAddressesWalletManagerUpdater {
    func updateWalletManager(address: any Address) async throws {
        try await updateWalletManager(addresses: [address])
    }

    func updateWalletManager(address: String) async throws {
        let desc = "Shouldn't called for `MultiAddressesWalletManagerUpdater`"
        assertionFailure(desc)
        throw WalletManagerUpdaterError.wrongMethodCalled(desc)
    }
}

// MARK: - MultiAddressesWalletManagerUpdater

public protocol MultiAddressesWalletManagerUpdater: AnyObject {
    func updateWalletManager(addresses: [any Address]) async throws
}

// MARK: - XPUBWalletManagerUpdater

public protocol XPUBWalletManagerUpdater {
    func updateWalletManager(xpub: String) async throws
}

public enum WalletManagerUpdaterError: LocalizedError {
    case wrongMethodCalled(String)

    public var errorDescription: String? {
        switch self {
        case .wrongMethodCalled(let desc): "Wrong method called \(desc)"
        }
    }
}
