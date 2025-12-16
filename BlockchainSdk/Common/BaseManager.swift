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
import UIKit // [REDACTED_TODO_COMMENT]

private extension DispatchQueue {
    static let baseManagerUpdateQueue = DispatchQueue(label: "com.tangem.BaseManager.updateQueue", attributes: .concurrent)
}

class BaseManager {
    private var _tokens: [Token] = []
    private let _wallet: CurrentValueSubject<Wallet, Never>
    private let _state: CurrentValueSubject<WalletManagerState, Never> = .init(.initial)

    private let _updateQueue: DispatchQueue
    private var _latestUpdateTime: Date?
    private var _updatingPublisher: PassthroughSubject<Void, Never>?
    private var _updatingSubscription: Cancellable?

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
        let _ = print("\(#function) called at \(CACurrentMediaTime())")
        _latestUpdateTime = nil
        _updatingSubscription?.cancel()
        _updatingSubscription = nil
    }

    func updatePublisher() -> AnyPublisher<Void, Never> {
        // Use sync here because every WalletModel can call this method in same time from different threads
        // It can be cause of the race condition to initiate update and create `_updatingPublisher`
        return _updateQueue.sync {
            let logger = BSDKLogger.tag("BaseManager")
            let walletName = "wallet \(wallet.blockchain.displayName) \(wallet.address)"

            // If updating already in process return updating Publisher
            if _updatingSubscription != nil, let updatePublisher = _updatingPublisher {
                logger.info(self, "Double updating request for \(walletName). Return existing updating publisher")
                return updatePublisher.eraseToAnyPublisher()
            }

            if let latestUpdateTime = _latestUpdateTime, latestUpdateTime.distance(to: .now) < BaseManager.config.timeToUpdate {
                logger.info(self, "Frequently updating requests for \(walletName). Do not start the updating")
                assert(_updatingPublisher == nil)

                return Just(()).eraseToAnyPublisher()
            }

            logger.info(self, "Start updating \(walletName)")
            logger.info(self, "Start sending \(walletName)")
            _state.send(.loading)
            logger.info(self, "Finish sending \(walletName)")

            _updatingSubscription = makeUpdatePublisher()
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self else { return }

                    switch completion {
                    case .failure(let error):
                        logger.error(self, "Updating \(walletName) is error", error: error)
                        _state.send(.failed(error))
                    case .finished:
                        logger.info(self, "Updating \(walletName) is success")
                        _state.send(.loaded)
                        _latestUpdateTime = Date()
                    }
                    logger.info(self, "Test 1 \(walletName)")
                    _updatingPublisher?.send(())
                    _updatingSubscription = nil
                    _updatingPublisher = nil
                    logger.info(self, "Test 3 \(walletName)")
                }, receiveValue: { _ in })

            if let _updatingPublisher {
                return _updatingPublisher.eraseToAnyPublisher()
            }

            logger.info(self, "Start creating updatePublisher \(walletName)")
            let updatePublisher = PassthroughSubject<Void, Never>()
            _updatingPublisher = updatePublisher
            logger.info(self, "Finish creating updatePublisher \(walletName)")

            return updatePublisher.eraseToAnyPublisher()
        }
    }

    private func makeUpdatePublisher() -> AnyPublisher<Void, Error> {
        let logger = BSDKLogger.tag("BaseManager")
        let walletName = "wallet \(wallet.blockchain.displayName) \(wallet.address)"

        return Future<Void, Error> { [weak self] promise in
            self?.update { result in
                switch result {
                case .success:
                    if let self {
                        logger.info(self, "Successful update \(walletName)")
                    }
                    promise(.success(()))
                case .failure(let error):
                    if let self {
                        logger.info(self, "Failed update \(walletName)")
                    }
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
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
        objectDescription(self)
    }
}

// MARK: - Config

extension BaseManager {
    static let config = Config()

    struct Config {
        let timeToUpdate: TimeInterval = 10
    }
}
