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

private extension DispatchQueue {
    static let baseManagerUpdateQueue = DispatchQueue(label: "com.tangem.BaseManager.updateQueue", attributes: .concurrent)
}

class BaseManager {
    private var _tokens: [Token] = []
    private let _wallet: CurrentValueSubject<Wallet, Never>
    private let _state: CurrentValueSubject<WalletManagerState, Never> = .init(.initial)

    private let _updateQueue: DispatchQueue
    private var _latestUpdateTime: Date?
    private var _updatingPublisher: AnyPublisher<Void, Never>?

    var cancellable: Cancellable?

    init(wallet: Wallet) {
        _wallet = .init(wallet)
        _updateQueue = DispatchQueue(label: "com.tangem.\(wallet.blockchain.coinId).updateQueue", target: .baseManagerUpdateQueue)
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

    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        fatalError("Have to be overridden")
    }
}

// MARK: - WalletProvider

extension BaseManager: WalletUpdater {
    func setNeedsUpdate() {
        _latestUpdateTime = nil
    }

    func updatePublisher() -> AnyPublisher<Void, Never> {
        // Use sync here because every WalletModel can call this method in same time from different threads
        // It can be cause of the race condition to initiate update and create `_updatingPublisher`
        return _updateQueue.sync {
            let logger = BSDKLogger.tag("BaseManager")
            let walletName = "wallet \(wallet.blockchain.displayName)"

            // If updating already in process return updating Publisher
            if let updatePublisher = _updatingPublisher {
                logger.info(self, "Double updating request for \(walletName). Return existing updating publisher")
                return updatePublisher.eraseToAnyPublisher()
            }

            if let latestUpdateTime = _latestUpdateTime, latestUpdateTime.distance(to: .now) < BaseManager.config.timeToUpdate {
                logger.info(self, "Frequently updating requests for \(walletName). Do not start the updating")
                assert(_updatingPublisher == nil)

                return Just(()).eraseToAnyPublisher()
            }

            logger.info(self, "Start updating \(walletName)")
            let updatePublisher = Future<Void, Never> { [weak self] promise in
                self?._state.send(.loading)

                self?.update { [weak self] result in
                    switch result {
                    case .success:
                        logger.info(self, "Updating \(walletName) is success")

                        self?._state.send(.loaded)
                        self?._latestUpdateTime = Date()

                    case .failure(let error):
                        logger.error(self, "Updating \(walletName) is error", error: error)

                        self?._state.send(.failed(error))
                    }

                    self?._updatingPublisher = nil
                    promise(.success(()))
                }
            }
            .eraseToAnyPublisher()

            _updatingPublisher = updatePublisher
            return updatePublisher
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

// MARK: - Config

extension BaseManager: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self)
    }
}

// MARK: - Config

extension BaseManager {
    static let config = Config()

    struct Config {
        let timeToUpdate: TimeInterval = 10
    }
}
