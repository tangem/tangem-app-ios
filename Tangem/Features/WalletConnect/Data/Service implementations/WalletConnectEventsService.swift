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

        let bitcoinNetworksInSessions = Set(
            dApps
                .flatMap(\.dAppBlockchains)
                .compactMap { dAppBlockchain -> Bool? in
                    if case .bitcoin(let testnet) = dAppBlockchain.blockchain {
                        return testnet
                    }

                    return nil
                }
        )

        guard bitcoinNetworksInSessions.isNotEmpty else {
            return
        }

        for isTestnet in bitcoinNetworksInSessions {
            let blockchain: BlockchainSdk.Blockchain = .bitcoin(testnet: isTestnet)

            // Mirror WalletConnectBitcoinGetAccountAddressesHandler.handle() response payload shape.
            guard let walletModel = selectedUserWalletModel.wcWalletModelProvider.getModel(with: blockchain.networkId) else {
                WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Bitcoin wallet model not found for blockchain: \(blockchain).")
                continue
            }

            let pathString = walletModel.tokenItem.blockchainNetwork.derivationPath?.rawPath

            let responses: [WalletConnectBtcAccountAddressResponse] = walletModel.addresses.map {
                WalletConnectBtcAccountAddressResponse(
                    address: $0.value,
                    path: pathString,
                    intention: "payment"
                )
            }

            // We need this workaround because `AnyCodable(responses)' crashes inside reown lib.
            // That strange beaucse it works fine in WalletConnectBitcoinGetAccountAddressesHandler
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
}

enum WCAppEvent {
    case dappConnected([WalletConnectConnectedDApp])
    case balanceChanged([WalletConnectConnectedDApp], BlockchainSdk.Blockchain)
}

enum WCEvent: String {
    case bip122AddressesChanged = "bip122_addressesChanged"
}
