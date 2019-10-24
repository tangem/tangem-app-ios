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
    override public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            scanWithNfc(environment: environment, callback: callback)
        } else {
            scanWithNdef(environment: environment, callback: callback)
        }
    }
    
    func scanWithNdef(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommandNdef()
        sendCommand(readCommand, environment: environment) { firstResult in
            switch firstResult {
            case .completion(let error):
                if let error = error {
                    callback(.completion(error))
                }
            case .event(var firstResponse):
                guard let firstChallenge = firstResponse.challenge,
                    let firstSalt = firstResponse.salt,
                    let publicKey = firstResponse.walletPublicKey,
                    let firstHashes = firstResponse.signedHashes else {
                        callback(.event(.onRead(firstResponse))) //card has no wallet
                        callback(.completion())
                        return
                }
                
                self.sendCommand(readCommand, environment: environment) { secondResult in
                    switch secondResult {
                    case .completion(let error):
                        if let error = error {
                            callback(.completion(error))
                        }
                    case .event(let secondResponse):
                        callback(.event(.onRead(secondResponse)))
                        guard let secondHashes = secondResponse.signedHashes,
                            let secondChallenge = secondResponse.challenge,
                            let walletSignature = secondResponse.walletSignature,
                            let secondSalt  = secondResponse.salt else {
                                callback(.completion(TaskError.cardError))
                                return
                        }
                        
                        if secondHashes > firstHashes {
                            firstResponse.signedHashes = secondHashes
                        }
                        
                        if firstChallenge == secondChallenge || firstSalt == secondSalt {
                            callback(.event(.onVerify(false)))
                            callback(.completion())
                            return
                        }
                        
                        if let verifyResult = CryptoUtils.vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                 publicKey: publicKey,
                                                                 message: firstChallenge + firstSalt,
                                                                 signature: walletSignature) {
                            callback(.event(.onVerify(verifyResult)))
                            callback(.completion())
                        } else {
                            callback(.completion(TaskError.vefificationFailed))
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    func scanWithNfc(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) { readResult in
            switch readResult {
            case .completion(let error):
                if let error = error {
                    self.cardReader.stopSession()
                    callback(.completion(error))
                }
            case .event(let readResponse):
                callback(.event(.onRead(readResponse)))
                guard let cardStatus = readResponse.status, cardStatus == .loaded else {
                    self.cardReader.stopSession()
                    callback(.completion())
                    return
                }
                
                guard let curve = readResponse.curve, let publicKey = readResponse.walletPublicKey else {
                    self.cardReader.stopSession()
                    callback(.completion(TaskError.cardError))
                    return
                }
                
                guard let challenge = CryptoUtils.generateRandomBytes(count: 16) else {
                    self.cardReader.stopSession()
                    callback(.completion(TaskError.vefificationFailed))
                    return
                }
                
                let checkWalletCommand = CheckWalletCommand(pin1: environment.pin1, cardId: readResponse.cardId, challenge: challenge)
                self.sendCommand(checkWalletCommand, environment: environment) { checkWalletResult in
                    self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                    self.cardReader.stopSession()
                    switch checkWalletResult {
                    case .completion(let error):
                        if let error = error {
                            callback(.completion(error))
                        }
                    case .event(let checkWalletResponse):
                        if let verifyResult = CryptoUtils.vefify(curve: curve,
                                                                 publicKey: publicKey,
                                                                 message: challenge + checkWalletResponse.salt,
                                                                 signature: checkWalletResponse.walletSignature) {
                            callback(.event(.onVerify(verifyResult)))
                            callback(.completion())
                        } else {
                            callback(.completion(TaskError.vefificationFailed))
                        }
                    }
                }
            }
        }
    }
}
