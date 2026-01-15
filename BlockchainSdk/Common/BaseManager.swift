//
//  BaseManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

private let BaseManagerLogger = BSDKLogger.tag("BaseManager")

class BaseManager {
    private var _tokens: [Token] = []
    private let _wallet: CurrentValueSubject<Wallet, Never>
    private let _state: CurrentValueSubject<WalletManagerState, Never> = .init(.initial)

    private var latestUpdateTime: Date?
    private var updatingProcessor: SingleTaskProcessor<Void, Never> = .init()

    /// Default config. Can be overridden
    var config: Config = .init()

    var cancellable: Cancellable?

    init(wallet: Wallet) {
        _wallet = .init(wallet)
    }

    /// Can not be in extension because it can be overridden
    func removeToken(_ token: Token) {
        _tokens.removeAll(where: { $0 == token })
        wallet.clearAmount(for: token)
    }

    /// Can not be in extension because it can be overridden
    func addToken(_ token: Token) {
        if !_tokens.contains(token) {
            _tokens.append(token)
        }
    }

    func updateWalletManager() async throws {
        assertionFailure("Has to be overridden")
        throw InternalError.updateMethodHaveToBeOverridden
    }
}

// MARK: - WalletProvider

extension BaseManager: WalletUpdater {
    func setNeedsUpdate() {
        latestUpdateTime = nil
    }

    func update() async {
        if let latestUpdateTime, latestUpdateTime.distance(to: .now) < config.timeToUpdate {
            BaseManagerLogger.info(self, "Frequently updating requests. Do not start the updating")
            return
        }

        await updatingProcessor.execute { [weak self] in
            await self?.runUpdating()
        }

        latestUpdateTime = Date()
    }

    private func runUpdating() async {
        do {
            BaseManagerLogger.info(self, "Start updating")
            _state.send(.loading)

            try await updateWalletManager()
            try Task.checkCancellation()

            BaseManagerLogger.info(self, "Updating is success")
            _state.send(.loaded)
        } catch let error as CancellationError {
            BaseManagerLogger.warning(self, "Updating is cancelled. Check it. Unusual behaviour")
            _state.send(.failed(error))
        } catch {
            BaseManagerLogger.error(self, "Updating is error", error: error)
            _state.send(.failed(error))
        }
    }
}

// MARK: - WalletProvider

extension BaseManager: WalletProvider {
    var wallet: Wallet {
        get { _wallet.value }
        set { _wallet.value = newValue }
    }

    var state: WalletManagerState { _state.value }

    var walletPublisher: AnyPublisher<Wallet, Never> { _wallet.eraseToAnyPublisher() }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { _state.eraseToAnyPublisher() }
}

// MARK: - TokensWalletProvider

extension BaseManager: TokensWalletProvider {
    var cardTokens: [Token] { _tokens }
}

// MARK: - CustomStringConvertible

extension BaseManager: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: ["walletName": wallet.blockchain.displayName])
    }
}

// MARK: - Config

extension BaseManager {
    static let config = Config()

    struct Config {
        let timeToUpdate: TimeInterval

        init(timeToUpdate: TimeInterval = 10) {
            self.timeToUpdate = timeToUpdate
        }
    }
}

// MARK: - Internal Error

extension BaseManager {
    enum InternalError: LocalizedError {
        case updateMethodHaveToBeOverridden
    }
}
