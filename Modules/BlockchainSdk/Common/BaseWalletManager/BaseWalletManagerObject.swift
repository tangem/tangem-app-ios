//
//  BaseWalletManagerObject.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemMacro

public typealias BaseWalletManagerObject = BaseWalletManagerUpdater & WalletProvider & WalletManagerUpdater & WalletManagerStateProvider & WalletTokensProvider

// MARK: - WalletProvider

public protocol WalletProvider: AnyObject {
    var wallet: Wallet { get set }
    var walletPublisher: AnyPublisher<Wallet, Never> { get }
}

extension WalletProvider {
    var defaultSourceAddress: String { wallet.address }
}

// MARK: - WalletManagerUpdater

public protocol WalletManagerUpdater: AnyObject {
    /// Reset the last updating time
    func setNeedsUpdate()
    func update() async
}

// MARK: - WalletManagerStateProvider

public protocol WalletManagerStateProvider: AnyObject {
    var state: WalletManagerState { get }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { get }
}

@CaseFlagable
public enum WalletManagerState {
    case initial
    case loading
    case loaded
    case failed(Error)
}

// MARK: - WalletTokensProvider

public protocol WalletTokensProvider {
    var cardTokens: [Token] { get }

    func removeToken(_ token: Token)
    func addToken(_ token: Token)
}

public extension WalletTokensProvider {
    func addTokens(_ tokens: [Token]) {
        tokens.forEach { addToken($0) }
    }
}
