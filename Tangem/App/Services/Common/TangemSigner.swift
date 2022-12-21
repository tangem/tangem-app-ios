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

    var signPublisher: AnyPublisher<Card, Never> {
        _signPublisher.eraseToAnyPublisher()
    }

    private var _signPublisher: PassthroughSubject<Card, Never> = .init()
    private var initialMessage: Message { .init(header: nil, body: L10n.initialMessageSignBody) }
    private let cardId: String?
    private let twinKey: TwinKey?

    init(with cardId: String?) {
        self.init(cardId: cardId, twinKey: nil)
    }

    init(with twinKey: TwinKey) {
        self.init(cardId: nil, twinKey: twinKey)
    }

    private init(cardId: String?, twinKey: TwinKey?) {
        self.cardId = cardId
        self.twinKey = twinKey
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Future<[Data], Error> { promise in
            let signCommand = SignAndReadTask(hashes: hashes,
                                              walletPublicKey: walletPublicKey.seedKey,
                                              pairWalletPublicKey: twinKey?.getPairKey(for: walletPublicKey.seedKey),
                                              derivationPath: walletPublicKey.derivationPath)

            self.sdkProvider.sdk.startSession(with: signCommand, cardId: self.cardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    self._signPublisher.send(response.card)
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
}

struct TwinKey {
    let key1: Data
    let key2: Data

    func getPairKey(for walletPublicKey: Data) -> Data? {
        if walletPublicKey == key1 {
            return key2
        }

        if walletPublicKey == key2 {
            return key1
        }

        return nil
    }
}
