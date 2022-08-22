//
//  TangemSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation
import TangemSdk
import BlockchainSdk
import Combine

struct TangemSigner: TransactionSigner {
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding
    @Injected(\.appWarningsService) private var warningsService: AppWarningsProviding

    private var initialMessage: Message { .init(header: nil, body: "initial_message_sign_body".localized) }
    private let cardId: String?

    init(with cardId: String?) {
        self.cardId = cardId
    }

    init(with card: Card) {
        if let backupStatus = card.backupStatus, backupStatus.isActive {
            self.init(with: nil)
        } else {
            self.init(with: card.cardId)
        }
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Future<[Data], Error> { promise in
            let signCommand = SignAndReadTask(hashes: hashes,
                                              walletPublicKey: walletPublicKey.seedKey,
                                              derivationPath: walletPublicKey.derivationPath)

            self.sdkProvider.sdk.startSession(with: signCommand, cardId: self.cardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    self.updateWarningsIfNeeded(with: response.card)
                    promise(.success(response.signatures))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map { $0[0] }
            .eraseToAnyPublisher()
    }

    private func updateWarningsIfNeeded(with card: Card) {
        warningsService.didSign(with: card)
    }
}
