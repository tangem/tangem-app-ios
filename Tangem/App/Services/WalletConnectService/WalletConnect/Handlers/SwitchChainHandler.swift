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

class SwitchChainHandler: TangemWalletConnectRequestHandler {
    @Injected(\.scannedCardsRepository) private var scannedCardsRepo: ScannedCardsRepository
    @Injected(\.tokenItemsRepository) private var tokenItemsRepository: TokenItemsRepository

    var action: WalletConnectAction { .switchChain }

    unowned var delegate: WalletConnectHandlerDelegate?
    unowned var dataSource: WalletConnectHandlerDataSource?

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
        let wallet = session.wallet

        guard let oldWalletInfo = session.session.walletInfo else {
            throw WalletConnectServiceError.sessionNotFound
        }

        guard let card = scannedCardsRepo.cards[wallet.cid] else {
            throw WalletConnectServiceError.cardNotFound
        }

        let supportedBlockchains = SupportedTokenItems().blockchains(for: [.secp256k1], isTestnet: card.isTestnet)

        let supportedChainIds = supportedBlockchains.compactMap { $0.chainId }
        guard supportedChainIds.contains(chainId) else {
            throw WalletConnectServiceError.unsupportedNetwork
        }

        let newBlockchain = supportedBlockchains.first(where: { $0.chainId == chainId })!

        let items = tokenItemsRepository.getItems(for: wallet.cid)
        let currentChainIds = items.compactMap { $0.blockchainNetwork.blockchain.chainId }

        guard currentChainIds.contains(chainId) else {
            throw WalletConnectServiceError.networkNotFound(name: newBlockchain.displayName)
        }

        session.wallet.blockchain = newBlockchain
        dataSource?.updateSession(session)

        return Session.WalletInfo(approved: true,
                                  accounts: [wallet.address],
                                  chainId: chainId,
                                  peerId: oldWalletInfo.peerId,
                                  peerMeta: oldWalletInfo.peerMeta)
    }

    private func showError(_ error: Error) {
        DispatchQueue.main.async {
            UIApplication.modalFromTop(
                WalletConnectUIBuilder.makeAlert(for: .error, message: error.localizedDescription)
            )
        }
    }
}
