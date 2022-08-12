//
//  WalletConnectCardScanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BlockchainSdk
import WalletConnectSwift

class WalletConnectCardScanner {
    @Injected(\.tangemSdkProvider) var tangemSdkProvider: TangemSdkProviding
    @Injected(\.scannedCardsRepository) var scannedCardsRepository: ScannedCardsRepository

    func scanCard(for dAppInfo: Session.DAppInfo) -> AnyPublisher<(CardInfo, WalletInfo), Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.tangemSdkProvider.sdk.startSession(with: AppScanTask(),
                                                        initialMessage: Message(header: "wallet_connect_scan_card_message".localized)) { [weak self] result in
                    guard let self = self else { return }

                    switch result {
                    case .success(let card):
                        do {
                            let cardInfo = card.getCardInfo()
                            let walletInfo = try self.walletInfo(for: cardInfo, dAppInfo: dAppInfo)
                            promise(.success((cardInfo, walletInfo)))
                        } catch {
                            print("Failed to receive wallet info for with id: \(card.card.cardId)")
                            promise(.failure(error))
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func walletInfo(for cardInfo: CardInfo, dAppInfo: Session.DAppInfo) throws -> WalletInfo {
        let config = UserWalletConfigFactory(cardInfo).makeConfig()

        guard config.hasFeature(.walletConnect) else {
            throw WalletConnectServiceError.notValidCard
        }

        guard let blockchainNetwork = config.selectNetwork(for: dAppInfo) else {
            throw WalletConnectServiceError.unsupportedNetwork
        }

        let cardModel = CardViewModel(cardInfo: cardInfo)
        cardModel.updateState()

        let wallet = cardModel.walletModels?
            .first(where: { $0.blockchainNetwork == blockchainNetwork })
            .map { $0.wallet }

        guard let wallet = wallet else {
            throw WalletConnectServiceError.networkNotFound(name: blockchainNetwork.blockchain.displayName)
        }

        scannedCardsRepository.add(cardInfo)

        let derivedKey = wallet.publicKey.blockchainKey != wallet.publicKey.seedKey ? wallet.publicKey.blockchainKey : nil

        return WalletInfo(cid: cardInfo.card.cardId,
                          walletPublicKey: wallet.publicKey.seedKey,
                          derivedPublicKey: derivedKey,
                          derivationPath: wallet.publicKey.derivationPath,
                          blockchain: blockchainNetwork.blockchain)
    }
}
