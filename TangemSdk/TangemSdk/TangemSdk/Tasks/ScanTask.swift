//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum ScanEvent {
    case onRead(Card)
    case onVerify(Bool)
}

public final class ScanTask: Task<ScanEvent> {
    override public func onRun(environment: CardEnvironment, completion: @escaping (TaskEvent<ScanEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            scanWithNfc(environment: environment, completion: completion)
        } else {
            scanWithNdef(environment: environment, completion: completion)
        }
    }
    
    func scanWithNdef(environment: CardEnvironment, completion: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommandNdef()
        sendCommand(readCommand, environment: environment) { firstResult in
            switch firstResult {
            case .failure(let error):
                self.cardReader.stopSession()
                completion(.failure(error))
            case .success(_):
                break
            case .event(var firstResponse):
                guard let firstChallenge = firstResponse.challenge,
                    let firstSalt = firstResponse.salt,
                    let publicKey = firstResponse.walletPublicKey,
                    let firstHashes = firstResponse.signedHashes else {
                        completion(.event(.onRead(firstResponse))) //card has no wallet
                        completion(.success(environment))
                        return
                }
                
                self.sendCommand(readCommand, environment: environment) { secondResult in
                    switch secondResult {
                    case .failure(let error):
                        self.cardReader.stopSession()
                        completion(.failure(error))
                    case .success(_):
                        break
                    case .event(let secondResponse):
                        completion(.event(.onRead(secondResponse)))
                        guard let secondHashes = secondResponse.signedHashes,
                            let secondChallenge = secondResponse.challenge,
                            let walletSignature = secondResponse.walletSignature,
                            let secondSalt  = secondResponse.salt else {
                                completion(.failure(TaskError.cardError))
                                return
                        }
                        
                        if secondHashes > firstHashes {
                            firstResponse.signedHashes = secondHashes
                        }
                        
                        if firstChallenge != secondChallenge && firstSalt != secondSalt {
                            if let verifyResult = CryptoUtils.vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                     publicKey: publicKey,
                                                                     message: firstChallenge + firstSalt,
                                                                     signature: walletSignature) {
                                completion(.event(.onVerify(verifyResult)))
                                completion(.success(environment))
                            } else {
                                completion(.failure(TaskError.vefificationFailed))
                            }
                        } else {
                            completion(.failure(TaskError.cardError))
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    func scanWithNfc(environment: CardEnvironment, completion: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand(pin1: environment.pin1)
        sendCommand(readCommand, environment: environment) { readResult in
            switch readResult {
            case .failure(let error):
                self.cardReader.stopSession()
                completion(.failure(error))
            case .event(let readResponse):
                completion(.event(.onRead(readResponse)))
                guard let cardStatus = readResponse.status, cardStatus == .loaded else {
                    completion(.success(environment))
                    return
                }
                
                guard let curve = readResponse.curve, let publicKey = readResponse.walletPublicKey else {
                    self.cardReader.stopSession()
                    completion(.failure(TaskError.cardError))
                    return
                }
                
                guard let challenge = CryptoUtils.generateRandomBytes(count: 16) else {
                    self.cardReader.stopSession()
                    completion(.failure(TaskError.vefificationFailed))
                    return
                }
                
                let checkWalletCommand = CheckWalletCommand(pin1: environment.pin1, cardId: readResponse.cardId, challenge: challenge)
                self.sendCommand(checkWalletCommand, environment: environment) { checkWalletResult in
                    self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                    self.cardReader.stopSession()
                    switch checkWalletResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .event(let checkWalletResponse):
                        if let verifyResult = CryptoUtils.vefify(curve: curve,
                                                                 publicKey: publicKey,
                                                                 message: challenge + checkWalletResponse.salt,
                                                                 signature: checkWalletResponse.walletSignature) {
                            completion(.event(.onVerify(verifyResult)))
                            completion(.success(environment))
                        } else {
                            completion(.failure(TaskError.vefificationFailed))
                        }
                    case .success(_):
                        break
                    }
                }
            case .success(_):
                break
            }
        }
    }
}
