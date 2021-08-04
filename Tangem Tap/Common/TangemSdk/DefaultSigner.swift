//
//  DefaultSigner.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//
import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
import Combine

typealias TangemSigner = TransactionSigner

public class DefaultSigner: TangemSigner {
    public var initialMessage: Message? = nil
    weak var delegate: SignerDelegate? = nil
    
    private let tangemSdk: TangemSdk
    
    public init(tangemSdk: TangemSdk, initialMessage: Message? = nil) {
        self.initialMessage = initialMessage
        self.tangemSdk = tangemSdk
    }
    
    public func sign(hashes: [Data], cardId: String, walletPublicKey: Data) -> AnyPublisher<[Data], Error> {
        let future = Future<[Data], Error> {[unowned self] promise in
            let signCommand = SignAndReadTask(hashes: hashes, walletPublicKey: walletPublicKey)
            self.tangemSdk.startSession(with: signCommand, cardId: cardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    self.delegate?.onSign(response.card)
                    promise(.success(response.signatures))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
    
    public func sign(hash: Data, cardId: String, walletPublicKey: Data) -> AnyPublisher<Data, Error> {
        let future = Future<Data, Error> {[unowned self] promise in
            let signCommand = SignAndReadTask(hashes: [hash], walletPublicKey: walletPublicKey)
            self.tangemSdk.startSession(with: signCommand, cardId: cardId, initialMessage: self.initialMessage) { signResult in
                switch signResult {
                case .success(let response):
                    self.delegate?.onSign(response.card)
                    promise(.success(response.signatures[0]))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
}

#endif
protocol SignerDelegate: AnyObject {
    func onSign(_ card: Card)
}
