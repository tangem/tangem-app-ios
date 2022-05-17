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
    
    var signedCardPublisher = PassthroughSubject<Card, Never>()
    
    private var initialMessage: Message { .init (header: nil, body: "initial_message_sign_body".localized) }
    
    public init() {}
    
    public func sign(hashes: [Data], cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        let future = Future<[Data], Error> {[unowned self] promise in
            let signCommand = SignAndReadTask(hashes: hashes,
                                              walletPublicKey: walletPublicKey.seedKey,
                                              derivationPath: walletPublicKey.derivationPath)
            self.sdkProvider.sdk.startSession(with: signCommand, cardId: cardId, initialMessage: self.initialMessage) { signResult in
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
    
    public func sign(hash: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], cardId: cardId, walletPublicKey: walletPublicKey)
            .map { $0[0] }
            .eraseToAnyPublisher()
    }
}
