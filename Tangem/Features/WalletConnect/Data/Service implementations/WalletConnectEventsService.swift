//
//  WalletConnectEventsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import BlockchainSdk
import struct Commons.AnyCodable
import TangemFoundation

final class WalletConnectEventsService {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    private let walletConnectService: any WCService

    init(walletConnectService: any WCService) {
        self.walletConnectService = walletConnectService
    }

    func handle(event: WCAppEvent) {
        switch event {
        case .dappConnected(let dApps):
            handleDappConnected(dApps: dApps)
        case .balanceChanged(let dApps, let blockchain):
            handleBalanceChanged(dApps: dApps, blockchain: blockchain)
        }
    }

    private func handleDappConnected(
        dApps: [WalletConnectConnectedDApp]
    ) {
        emitBitcoinAddressesChangedIfPossible(dApps: dApps)
    }

    private func handleBalanceChanged(dApps: [WalletConnectConnectedDApp], blockchain: BlockchainSdk.Blockchain) {
        guard case .bitcoin = blockchain else {
            return
        }

        // Filter dApps only for this specific bitcoin chain (mainnet/testnet).
        let filteredDApps = dApps.filter { dApp in
            dApp.dAppBlockchains.contains(where: { $0.blockchain.networkId == blockchain.networkId })
        }

        guard filteredDApps.isNotEmpty else {
            return
        }

        emitBitcoinAddressesChangedIfPossible(dApps: filteredDApps)
    }

    private func emitBitcoinAddressesChangedIfPossible(dApps: [WalletConnectConnectedDApp]) {
        guard let selectedUserWalletModel = userWalletRepository.selectedModel else {
            return
        }

        // Gets exact bitcoin chain from connected dApps to get wcChainId further.
        guard let wcBlockchain = dApps
            .flatMap(\.dAppBlockchains)
            .first(where: { dAppBlockchain in
                if case .bitcoin = dAppBlockchain.blockchain {
                    return true
                } else {
                    return false
                }
            })
        else { return }

        let blockchain = wcBlockchain.blockchain

        if FeatureProvider.isAvailable(.accounts) {
            let accountIds = Set(
                dApps.compactMap { dApp -> String? in
                    guard dApp.dAppBlockchains.contains(where: { $0.blockchain.networkId == blockchain.networkId }) else {
                        return nil
                    }

                    return dApp.accountId
                }
            )

            guard accountIds.isNotEmpty else {
                WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Account ID not found for blockchain: \(blockchain).")
                return
            }

            for accountId in accountIds {
                guard let walletModel = selectedUserWalletModel.wcAccountsWalletModelProvider.getModel(
                    with: blockchain.networkId,
                    accountId: accountId
                ) else {
                    WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Bitcoin wallet model not found for blockchain: \(blockchain) and accountId: \(accountId).")
                    continue
                }

                emitAddressesChangedEvent(for: walletModel, on: blockchain)
            }
        } else {
            guard let walletModel = selectedUserWalletModel.wcWalletModelProvider.getModel(with: blockchain.networkId) else {
                WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Bitcoin wallet model not found for blockchain: \(blockchain).")
                return
            }

            emitAddressesChangedEvent(for: walletModel, on: blockchain)
        }
    }
}

extension WalletConnectEventsService {
    private func emitAddressesChangedEvent(for walletModel: any WalletModel, on blockchain: BlockchainSdk.Blockchain) {
        let pathString = walletModel.tokenItem.blockchainNetwork.derivationPath?.rawPath

        let responses: [WalletConnectBtcAccountAddressResponse] = walletModel.addresses.map {
            WalletConnectBtcAccountAddressResponse(
                address: $0.value,
                path: pathString,
                intention: "payment"
            )
        }

        // We need this workaround because `AnyCodable(responses)' crashes inside reown lib.
        // That strange because it works fine in WalletConnectBitcoinGetAccountAddressesHandler
        let payload: [[String: Any]] = responses.map { response in
            [
                "address": response.address,
                "path": response.path ?? NSNull(),
                "intention": response.intention,
            ]
        }

        let event = Session.Event(
            name: WCEvent.bip122AddressesChanged.rawValue,
            data: AnyCodable(any: payload)
        )

        walletConnectService.emitEvent(event, on: blockchain)
    }
}

enum WCAppEvent {
    case dappConnected([WalletConnectConnectedDApp])
    case balanceChanged([WalletConnectConnectedDApp], BlockchainSdk.Blockchain)
}

enum WCEvent: String {
    case bip122AddressesChanged = "bip122_addressesChanged"
}
