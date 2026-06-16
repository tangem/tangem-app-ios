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
        case .balanceChanged(let dApps, let blockchain, let userWalletId):
            handleBalanceChanged(dApps: dApps, blockchain: blockchain, userWalletId: userWalletId)
        }
    }

    private func handleDappConnected(dApps: [WalletConnectConnectedDApp]) {
        let dAppsByWallet = Dictionary(grouping: dApps, by: { $0.userWalletID })
        for (walletId, walletDApps) in dAppsByWallet {
            guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == walletId }) else {
                continue
            }
            emitBitcoinAddressesChangedIfPossible(dApps: walletDApps, userWalletModel: userWalletModel)
        }
    }

    private func handleBalanceChanged(
        dApps: [WalletConnectConnectedDApp],
        blockchain: BlockchainSdk.Blockchain,
        userWalletId: String
    ) {
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

        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == userWalletId }) else {
            WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Wallet model not found for walletId: \(userWalletId).")
            return
        }

        emitBitcoinAddressesChangedIfPossible(dApps: filteredDApps, userWalletModel: userWalletModel)
    }

    private func emitBitcoinAddressesChangedIfPossible(
        dApps: [WalletConnectConnectedDApp],
        userWalletModel: any UserWalletModel
    ) {
        guard let blockchain = dApps.first?.dAppBlockchains.first(where: {
            if case .bitcoin = $0.blockchain {
                return true
            } else {
                return false
            }
        })?.blockchain else { return }

        let accountIds = Set(
            dApps
                .filter { $0.dAppBlockchains.contains(where: { $0.blockchain.networkId == blockchain.networkId }) }
                .map(\.accountId)
        )

        guard accountIds.isNotEmpty else {
            WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Account ID not found for blockchain: \(blockchain).")
            return
        }

        for accountId in accountIds {
            guard let walletModel = userWalletModel.wcAccountsWalletModelProvider.getModel(
                with: blockchain.networkId,
                accountId: accountId
            ) else {
                WCLogger.error(error: "Failed to emit \(WCEvent.bip122AddressesChanged.rawValue). Bitcoin wallet model not found for blockchain: \(blockchain) and accountId: \(accountId).")
                continue
            }

            emitAddressesChangedEvent(for: walletModel, on: blockchain)
        }
    }
}

extension WalletConnectEventsService {
    private func emitAddressesChangedEvent(for walletModel: any WalletModel, on blockchain: BlockchainSdk.Blockchain) {
        let pathString = walletModel.tokenItem.blockchainNetwork.derivationPath?.rawPath

        let responses: [WalletConnectBtcAccountAddressResponse] = walletModel.addressesString.map {
            WalletConnectBtcAccountAddressResponse(
                address: $0,
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
    case balanceChanged([WalletConnectConnectedDApp], BlockchainSdk.Blockchain, userWalletId: String)
}

enum WCEvent: String {
    case bip122AddressesChanged = "bip122_addressesChanged"
}
