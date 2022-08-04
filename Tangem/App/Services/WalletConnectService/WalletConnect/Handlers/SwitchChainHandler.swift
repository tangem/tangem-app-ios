//
//  SwitchChainHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import BlockchainSdk

class SwitchChainHandler: TangemWalletConnectRequestHandler {
    @Injected(\.scannedCardsRepository) private var scannedCardsRepo: ScannedCardsRepository
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository

    var action: WalletConnectAction { .switchChain }

    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?

    private var bag: Set<AnyCancellable> = []

    init(delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    func handle(request: Request) {
        do {
            let chainIdHexString = (try request.parameter(of: [String: String].self, at: 0))["chainId"]
            let address = try request.parameter(of: String.self, at: 1)
            let chainId = chainIdHexString.map { Data(hexString: $0) }?.toInt()

            guard let session = dataSource?.session(for: request, address: address),
                  let chainId = chainId else {
                delegate?.send(.reject(request), for: action)
                return
            }

            let sessionWalletInfo = try switchChain(session, chainId: chainId)
            delegate?.sendUpdate(for: session.session, with: sessionWalletInfo)
        } catch {
            delegate?.sendInvalid(request)
            if error is WalletConnectServiceError {
                showError(error)
            }
        }
    }

    private func switchChain(_ session: WalletConnectSession, chainId: Int) throws -> Session.WalletInfo  {
        var session = session
        let oldWalletInfo = session.wallet

        guard let oldSessionWalletInfo = session.session.walletInfo else {
            throw WalletConnectServiceError.sessionNotFound
        }

        guard let card = scannedCardsRepo.cards[oldWalletInfo.cid] else {
            throw WalletConnectServiceError.cardNotFound
        }

        let supportedBlockchains = Blockchain.supportedBlockchains.union(Blockchain.supportedTestnetBlockchains)

        guard let targetBlockchain = supportedBlockchains.first(where: { $0.chainId == chainId }) else {
            throw WalletConnectServiceError.unsupportedNetwork
        }

        let availableItems = tokenItemsRepository.getItems(for: oldWalletInfo.cid)
        guard let availableItem = availableItems.first(where: { $0.blockchainNetwork.blockchain.chainId == chainId }) else {
            throw WalletConnectServiceError.networkNotFound(name: targetBlockchain.displayName)
        }

        let availableWallet = WalletManagerAssembly.makeWalletModels(from: card, blockchainNetworks: [availableItem.blockchainNetwork])
            .filter { !$0.isCustom(.coin) }
            .first(where: { $0.wallet.blockchain == targetBlockchain })
            .map { $0.wallet }

        guard let wallet = availableWallet else {
            throw WalletConnectServiceError.networkNotFound(name: targetBlockchain.displayName)
        }

        let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil

        let walletInfo = WalletInfo(cid: card.cardId,
                                    walletPublicKey: wallet.publicKey.seedKey,
                                    derivedPublicKey: derivedKey,
                                    derivationPath: wallet.publicKey.derivationPath,
                                    blockchain: targetBlockchain)

        session.wallet = walletInfo
        dataSource?.updateSession(session)

        return Session.WalletInfo(approved: true,
                                  accounts: [wallet.address],
                                  chainId: chainId,
                                  peerId: oldSessionWalletInfo.peerId,
                                  peerMeta: oldSessionWalletInfo.peerMeta)
    }

    private func showError(_ error: Error) {
        DispatchQueue.main.async {
            UIApplication.modalFromTop(
                WalletConnectUIBuilder.makeAlert(for: .error, message: error.localizedDescription)
            )
        }
    }
}
