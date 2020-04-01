//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to read Tangem card and verify its private key.
/// Returns data from a Tangem card after successful completion of `ReadCommand` and `CheckWalletCommand`, subsequently.
@available(iOS 13.0, *)
public final class ScanTask: CardSessionRunnable {
    
    public typealias CommandResponse = Card
    public init() {}
    
    deinit {
        print("skantask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.errorProcessingCommand))
            return
        }
        
        guard let cardStatus = card.status, cardStatus == .loaded else {
            completion(.success(card))
            return
        }
        
        guard let curve = card.curve,
            let publicKey = card.walletPublicKey else {
                completion(.failure(.cardError))
                return
        }
        
        guard let checkWalletCommand = CheckWalletCommand(curve: curve, publicKey: publicKey) else {
            completion(.failure(.errorProcessingCommand))
            return
        }

        checkWalletCommand.run(in: session) { checkWalletResult in
            switch checkWalletResult {
            case .success(_):
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

public final class ScanTaskLegacy: CardSessionRunnable {
    public typealias CommandResponse = Card
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let readCommand = ReadCommand()
        readCommand.run(in: session) {firstResult in
            switch firstResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(var firstResponse):
                guard let firstChallenge = firstResponse.challenge,
                    let firstSalt = firstResponse.salt,
                    let publicKey = firstResponse.walletPublicKey,
                    let firstHashes = firstResponse.signedHashes else {
                        completion(.success(firstResponse))
                        return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    readCommand.run(in: session) {secondResult in
                        switch secondResult {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let secondResponse):
                            guard let secondHashes = secondResponse.signedHashes,
                                let secondChallenge = secondResponse.challenge,
                                let walletSignature = secondResponse.walletSignature,
                                let secondSalt  = secondResponse.salt else {
                                    completion(.failure(.cardError))
                                    return
                            }
                            
                            if secondHashes > firstHashes {
                                firstResponse.signedHashes = secondHashes
                            }
                            
                            if firstChallenge == secondChallenge || firstSalt == secondSalt {
                                completion(.failure(.verificationFailed))
                                return
                            }
                            
                            if let verifyResult = CryptoUtils.vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                     publicKey: publicKey,
                                                                     message: firstChallenge + firstSalt,
                                                                     signature: walletSignature) {
                                if verifyResult == true {
                                    completion(.success(secondResponse))
                                } else {
                                    completion(.failure(.errorProcessingCommand))
                                }
                            } else {
                                completion(.failure(.verificationFailed))
                            }
                        }
                    }
                }
            }
        }
    }
    
}
