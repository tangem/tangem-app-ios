//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
/**
 * Events that `ScanTask` returns on completion of its commands.
 * `onRead(Card)`: Contains data from a Tangem card after successful completion of `ReadCommand`.
 * `onVerify(Bool)`: Shows whether the Tangem card was verified on completion of `CheckWalletCommand`.
 */
public enum ScanEvent {
    case onRead(Card)
    case onVerify(Bool)
}

/// Task that allows to read Tangem card and verify its private key.
/// It performs two commands, `ReadCommand` and `CheckWalletCommand`, subsequently. 
public final class ScanTask: Task<ScanEvent> {
    override public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            guard let card = currentCard else {
                callback(.completion(TaskError.missingPreflightRead))
                return
            }
            
            scanWithNfc(environment: environment, currentCard: card,  callback: callback)
        } else {
            scanWithNdef(environment: environment, callback: callback)
        }
    }
    
    func scanWithNdef(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) {[unowned self] firstResult in
            switch firstResult {
            case .failure(let error):
                callback(.completion(error))
                self.reader.stopSession()
            case .success(var firstResponse):
                guard let firstChallenge = firstResponse.challenge,
                    let firstSalt = firstResponse.salt,
                    let publicKey = firstResponse.walletPublicKey,
                    let firstHashes = firstResponse.signedHashes else {
                        self.reader.stopSession()
                        callback(.event(.onRead(firstResponse))) //card has no wallet
                        callback(.completion())
                        return
                }
                
                self.sendCommand(readCommand, environment: environment) {[unowned self] secondResult in
                    switch secondResult {
                    case .failure(let error):
                        callback(.completion(error))
                        self.reader.stopSession()
                    case .success(let secondResponse):
                        callback(.event(.onRead(secondResponse)))
                        guard let secondHashes = secondResponse.signedHashes,
                            let secondChallenge = secondResponse.challenge,
                            let walletSignature = secondResponse.walletSignature,
                            let secondSalt  = secondResponse.salt else {
                                callback(.completion(TaskError.cardError))
                                self.reader.stopSession()
                                return
                        }
                        
                        if secondHashes > firstHashes {
                            firstResponse.signedHashes = secondHashes
                        }
                        
                        if firstChallenge == secondChallenge || firstSalt == secondSalt {
                            callback(.event(.onVerify(false)))
                            callback(.completion())
                            self.reader.stopSession()
                            return
                        }
                        
                        if let verifyResult = CryptoUtils.vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                 publicKey: publicKey,
                                                                 message: firstChallenge + firstSalt,
                                                                 signature: walletSignature) {
                            callback(.event(.onVerify(verifyResult)))
                            callback(.completion())
                        } else {
                            callback(.completion(TaskError.verificationFailed))
                        }
                        self.reader.stopSession()
                    }
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    func scanWithNfc(environment: CardEnvironment, currentCard: Card, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        callback(.event(.onRead(currentCard)))
        guard let cardStatus = currentCard.status, cardStatus == .loaded else {
            reader.stopSession()
            callback(.completion())
            return
        }
        
        guard let curve = currentCard.curve,
            let publicKey = currentCard.walletPublicKey else {
                let error = TaskError.cardError
                reader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
                return
        }
        
        guard let checkWalletCommand = CheckWalletCommand() else {
            let error = TaskError.errorProcessingCommand
            reader.stopSession(errorMessage: error.localizedDescription)
            callback(.completion(error))
            return
        }
        
        sendCommand(checkWalletCommand, environment: environment) {[unowned self] checkWalletResult in
            switch checkWalletResult {
            case .failure(let error):
                self.reader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
            case .success(let checkWalletResponse):
                self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                self.reader.stopSession()
                if let verifyResult = checkWalletResponse.verify(curve: curve, publicKey: publicKey, challenge: checkWalletCommand.challenge) {
                    callback(.event(.onVerify(verifyResult)))
                    callback(.completion())
                } else {
                    callback(.completion(TaskError.verificationFailed))
                }
            }
        }
    }
}
