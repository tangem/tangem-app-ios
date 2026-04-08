//
//  BaseWalletManager.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

private let BaseWalletManagerLogger = BSDKLogger.tag("BaseWalletManager")

class BaseWalletManager {
    private var _tokens: [Token] = []
    private let _wallet: CurrentValueSubject<Wallet, Never>
    private let _state: CurrentValueSubject<WalletManagerState, Never> = .init(.initial)

    private let config: UpdatingConfig = .init()

    private var latestUpdateTime: Date?
    private var singleTaskProcessor: SingleTaskProcessor<Void, Never> = .init()

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
}

// MARK: - WalletProvider

extension BaseWalletManager: WalletProvider {
    var wallet: Wallet {
        get { _wallet.value }
        set { _wallet.value = newValue }
    }

    var walletPublisher: AnyPublisher<Wallet, Never> { _wallet.eraseToAnyPublisher() }
}

// MARK: - WalletReplaceable

extension BaseWalletManager: WalletReplaceable {
    func update(wallet newWallet: Wallet) throws {
        guard newWallet.blockchain.networkId == wallet.blockchain.networkId else {
            throw InternalError.attemptToWalletUpdateWithDifferentNetworkId
        }

        _wallet.send(newWallet)
    }
}

// MARK: - WalletManagerUpdater

extension BaseWalletManager: WalletManagerUpdater {
    func setNeedsUpdate() {
        latestUpdateTime = nil
    }

    func update() async {
        if let latestUpdateTime, latestUpdateTime.distance(to: .now) < config.timeToUpdate {
            BaseWalletManagerLogger.info(self, "Frequently updating requests. Do not start the updating")
            return
        }

        await singleTaskProcessor.execute { [weak self] in
            await self?.startUpdating()
        }

        latestUpdateTime = Date()
    }

    private func startUpdating() async {
        do {
            BaseWalletManagerLogger.info(self, "Start updating")
            _state.send(.loading)

            let keyType = try wallet.updatingKeyType()
            switch (keyType, self) {
            case (.address(let address), let updater as BaseWalletManagerUpdater):
                try await updater.updateWalletManager(address: address)

            // Dogecoin, Ravencoin other BTC-like
            case (.address(let address), let updater as MultiAddressesWalletManagerUpdater):
                try await updater.updateWalletManager(addresses: [address])

            // Bitcoin, Cardano, etc.
            case (.addresses(let `default`, let legacy), let updater as MultiAddressesWalletManagerUpdater):
                try await updater.updateWalletManager(addresses: [`default`, legacy])

            // Ignore `legacy` address here. XDC, Decimal blockchains
            case (.addresses(let `default`, _), let updater as BaseWalletManagerUpdater):
                try await updater.updateWalletManager(address: `default`)

            case (.xpub(let xpub), let updater as XPUBWalletManagerUpdater):
                try await updater.updateWalletManager(xpub: xpub)

            default:
                throw InternalError.walletManagerUpdaterNotSetup
            }

            try Task.checkCancellation()

            BaseWalletManagerLogger.info(self, "Updating is success")
            _state.send(.loaded)
        } catch let error as CancellationError {
            BaseWalletManagerLogger.warning(self, "Updating is cancelled. Check it. Unusual behaviour")
            _state.send(.failed(error))
        } catch {
            BaseWalletManagerLogger.error(self, "Updating is error", error: error)
            _state.send(.failed(error))
        }
    }
}

// MARK: - WalletManagerStateProvider

extension BaseWalletManager: WalletManagerStateProvider {
    var state: WalletManagerState { _state.value }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { _state.eraseToAnyPublisher() }
}

// MARK: - WalletTokensProvider

extension BaseWalletManager: WalletTokensProvider {
    var cardTokens: [Token] { _tokens }
}

// MARK: - CustomStringConvertible

extension BaseWalletManager: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: ["walletName": wallet.blockchain.displayName])
    }
}

// MARK: - UpdatingConfig

extension BaseWalletManager {
    struct UpdatingConfig {
        let timeToUpdate: TimeInterval

        init(timeToUpdate: TimeInterval = 10) {
            self.timeToUpdate = timeToUpdate
        }
    }
}

// MARK: - Internal Error

extension BaseWalletManager {
    enum InternalError: LocalizedError {
        case walletManagerUpdaterNotSetup
        case attemptToWalletUpdateWithDifferentNetworkId

        var errorDescription: String? {
            switch self {
            case .walletManagerUpdaterNotSetup: "WalletManagerUpdater is not set"
            case .attemptToWalletUpdateWithDifferentNetworkId: "Attempt to update wallet with different network ID"
            }
        }
    }
}
