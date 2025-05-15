//
//  TangemSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation
import TangemLocalization
import TangemSdk
import BlockchainSdk
import Combine

struct TangemSigner: TransactionSigner {
    var signPublisher: AnyPublisher<Card, Never> {
        latestSigner
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private(set) var latestSigner: CurrentValueSubject<Card?, Never> = .init(nil)
    private var initialMessage: Message { .init(header: nil, body: Localization.initialMessageSignBody) }
    private let filter: SessionFilter
    private let twinKey: TwinKey?
    private let sdk: TangemSdk

    init(filter: SessionFilter, sdk: TangemSdk, twinKey: TwinKey?) {
        self.filter = filter
        self.twinKey = twinKey
        self.sdk = sdk
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Future<[SignatureInfo], Error> { promise in
            let signCommand = SignAndReadTask(
                hashes: hashes,
                walletPublicKey: walletPublicKey.seedKey,
                pairWalletPublicKey: twinKey?.getPairKey(for: walletPublicKey.seedKey),
                derivationPath: walletPublicKey.derivationPath
            )

            sdk.startSession(with: signCommand, filter: filter, initialMessage: initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    latestSigner.send(response.card)
                    let signatures = zip(hashes, response.signatures).map { hash, signature in
                        SignatureInfo(signature: signature, publicKey: walletPublicKey.blockchainKey, hash: hash)
                    }
                    promise(.success(signatures))
                case .failure(let error):
                    promise(.failure(error))
                }

                withExtendedLifetime(signCommand) {}
            }
        }
        .eraseToAnyPublisher()
    }

    func sign(
        dataToSign: [SignData],
        seedKey: Data
    ) -> AnyPublisher<[(signature: Data, publicKey: Data)], Error> {
        let signCommand = MultipleSignTask(dataToSign: dataToSign, seedKey: seedKey)
        return sdk.startSessionPublisher(with: signCommand, filter: filter, initialMessage: initialMessage)
            .mapError { $0 }
            .handleEvents(receiveOutput: { response in
                if let lastResponse = response.last {
                    latestSigner.send(lastResponse.card)
                }
            })
            .map { response in
                return response.map { ($0.signature, $0.publicKey) }
            }
            .eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
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
