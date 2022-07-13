//
//  DefaultSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation
import TangemSdk
import BlockchainSdk
import Combine

public class DefaultSigner: TransactionSigner, TransactionSignerPublisher {
    @Injected(\.tangemSdkProvider) private var sdkProvider: TangemSdkProviding
    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    var signedCardPublisher = PassthroughSubject<Card, Never>()

    private var initialMessage: Message { .init(header: nil, body: "initial_message_sign_body".localized) }

    public init() {}

    public func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        let requiredCardId: String?

        let card = cardsRepository.lastScanResult.cardModel?.cardInfo.card
        if let backupStatus = card?.backupStatus, backupStatus.isActive {
            requiredCardId = nil
        } else {
            requiredCardId = card?.cardId
        }

        let future = Future<[Data], Error> { [unowned self] promise in
            let signCommand = SignAndReadTask(hashes: hashes,
                                              walletPublicKey: walletPublicKey.seedKey,
                                              derivationPath: walletPublicKey.derivationPath)
            self.sdkProvider.sdk.startSession(with: signCommand, cardId: requiredCardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    self.signedCardPublisher.send(response.card)
                    promise(.success(response.signatures))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }

    public func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map { $0[0] }
            .eraseToAnyPublisher()
    }
}
