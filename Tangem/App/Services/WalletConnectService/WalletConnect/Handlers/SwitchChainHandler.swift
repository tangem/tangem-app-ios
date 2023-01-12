//
//  SwitchChainHandler.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import BlockchainSdk

class SwitchChainHandler: TangemWalletConnectRequestHandler {
    var action: WalletConnectAction { .switchChain }

    weak var delegate: WalletConnectHandlerDelegate?
    weak var dataSource: WalletConnectHandlerDataSource?

    private var bag: Set<AnyCancellable> = []

    init(delegate: WalletConnectHandlerDelegate, dataSource: WalletConnectHandlerDataSource) {
        self.delegate = delegate
        self.dataSource = dataSource
    }

    func handle(request: Request) {
        Task {
            await handle(request: request)
        }
    }

    private func handle(request: Request) async {
        do {
            let chainIdHexString = (try request.parameter(of: [String: String].self, at: 0))["chainId"]
            let chainId = chainIdHexString.map { Data(hexString: $0) }?.toInt()

            guard let session = dataSource?.session(for: request),
                  let chainId = chainId else {
                delegate?.send(.reject(request), for: action)
                return
            }

            let sessionWalletInfo = try await switchChain(session, chainId: chainId)
            delegate?.sendUpdate(for: session.session, with: sessionWalletInfo)
        } catch {
            delegate?.sendReject(for: request, with: error, for: action)
        }
    }

    private func switchChain(_ session: WalletConnectSession, chainId: Int) async throws -> Session.WalletInfo  {
        var session = session
        let oldWalletInfo = session.wallet

        guard let oldSessionWalletInfo = session.session.walletInfo else {
            throw WalletConnectServiceError.sessionNotFound
        }

        let supportedBlockchains = Blockchain.supportedBlockchains.union(Blockchain.supportedTestnetBlockchains)

        guard let targetBlockchain = supportedBlockchains.first(where: { $0.chainId == chainId }) else {
            throw WalletConnectServiceError.unsupportedNetwork
        }

        let availableWallets = dataSource?.cardModel.walletModels
            .filter { $0.wallet.blockchain == targetBlockchain }
            .map { $0.wallet } ?? []

        guard !availableWallets.isEmpty else {
            throw WalletConnectServiceError.networkNotFound(name: targetBlockchain.displayName)
        }

        let wallet: Wallet

        if availableWallets.count == 1 {
            wallet = availableWallets.first!
        } else {
            wallet = try await selectWallet(from: availableWallets)
        }

        let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil

        let walletInfo = WalletInfo(walletPublicKey: wallet.publicKey.seedKey,
                                    derivedPublicKey: derivedKey,
                                    derivationPath: wallet.publicKey.derivationPath,
                                    blockchain: targetBlockchain)

        if wallet.address != oldWalletInfo.address {
            throw WalletConnectServiceError.switchChainNotSupported
        }

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

    private func selectWallet(from wallets: [Wallet]) async throws -> Wallet {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let vc = WalletConnectUIBuilder.makeChainsSheet(wallets,
                                                                onAcceptAction: {
                                                                    continuation.resume(returning: $0)
                                                                },
                                                                onReject: {
                                                                    continuation.resume(throwing: WalletConnectServiceError.cancelled)
                                                                })

                UIApplication.modalFromTop(vc)
            }
        }
    }
}
