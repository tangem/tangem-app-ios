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
    override public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            scanWithNfc(environment: environment, callback: callback)
        } else {
            scanWithNdef(environment: environment, callback: callback)
        }
    }
    
    func scanWithNdef(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) { firstResult in
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
                
                self.sendCommand(readCommand, environment: environment) { secondResult in
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
                        
                        if let verifyResult = CryptoUtils().vefify(curve: publicKey.count == 65 ? EllipticCurve.secp256k1 : EllipticCurve.ed25519,
                                                                 publicKey: publicKey,
                                                                 message: firstChallenge + firstSalt,
                                                                 signature: walletSignature) {
                            callback(.event(.onVerify(verifyResult)))
                            callback(.completion())
                        } else {
                            callback(.completion(TaskError.vefificationFailed))
                        }
                        self.reader.stopSession()
                    }
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    func scanWithNfc(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) { [weak self] readResult in
            switch readResult {
            case .failure(let error):
                self?.reader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
            case .success(let readResponse):
                callback(.event(.onRead(readResponse)))
                guard let cardStatus = readResponse.status, cardStatus == .loaded else {
                    self?.reader.stopSession()
                    callback(.completion())
                    return
                }
                
                guard let curve = readResponse.curve,
                    let publicKey = readResponse.walletPublicKey,
                    let cardId = readResponse.cardId else {
                        let error = TaskError.cardError
                        self?.reader.stopSession(errorMessage: error.localizedDescription)
                        callback(.completion(error))
                        return
                }
                
                guard let challenge = CryptoUtils().generateRandomBytes(count: 16) else {
                    let error = TaskError.cardError
                    self?.reader.stopSession(errorMessage: error.localizedDescription)
                    callback(.completion(error))
                    return
                }
                
                let checkWalletCommand = CheckWalletCommand(cardId: cardId, challenge: challenge)
                self?.sendCommand(checkWalletCommand, environment: environment) {[weak self] checkWalletResult in
                    switch checkWalletResult {
                    case .failure(let error):
                        self?.reader.stopSession(errorMessage: error.localizedDescription)
                        callback(.completion(error))
                    case .success(let checkWalletResponse):
                        self?.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                        self?.reader.stopSession()
                        if let verifyResult = CryptoUtils().vefify(curve: curve,
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
