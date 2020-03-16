//
//  ScanTaskExtended.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemSdk
/**
 * Events that `ScanTask` returns on completion of its commands.
 * `onRead(Card)`: Contains data from a Tangem card after successful completion of `ReadCommand`.
 * `onVerify(Bool)`: Shows whether the Tangem card was verified on completion of `CheckWalletCommand`.
 */
public enum ScanExtendedEvent {
    case onRead(Card)
    case onIssuerExtraDataRead(ReadIssuerExtraDataResponse)
    case onVerify(Bool)
}

/// Task that allows to read Tangem card and verify its private key.
/// It performs two commands, `ReadCommand` and `CheckWalletCommand`, subsequently.
public final class ScanTaskExtended: Task<ScanExtendedEvent> {
    
    private var issuerPublicKey: Data?
    
    private var issuerData = Data()
    private var issuerDataSize = 0
    
    public init(issuerPublicKey: Data? = nil) {
        super.init()
        self.issuerPublicKey = issuerPublicKey
    }
    
    override public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<ScanExtendedEvent>) -> Void) {
        if #available(iOS 13.0, *) {
            guard let card = currentCard else {
                reader.stopSession(errorMessage: TaskError.missingPreflightRead.localizedDescription)
                callback(.completion(TaskError.missingPreflightRead))
                return
            }
            
            if issuerPublicKey == nil {
                issuerPublicKey = card.issuerPublicKey
            }
            
            callback(.event(.onRead(card)))
            
            if card.cardData?.productMask?.contains(.card) ?? false {
                readData(with: environment) {[weak self] result in
                    switch result {
                    case .success(let response):
                        callback(.event(.onIssuerExtraDataRead(response)))
                        self?.scanWithNfc(environment: environment, currentCard: card,  callback: callback)
                    case .failure(let error):
                        self?.reader.stopSession(errorMessage: error.localizedDescription)
                        callback(.completion(error))
                    }
                }
            } else {
                scanWithNfc(environment: environment, currentCard: card,  callback: callback)
            }
            
        } else {
            scanWithNdef(environment: environment, callback: callback)
        }
    }
    
    func scanWithNdef(environment: CardEnvironment, callback: @escaping (TaskEvent<ScanExtendedEvent>) -> Void) {
        let readCommand = ReadCommand()
        sendCommand(readCommand, environment: environment) {firstResult in
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.sendCommand(readCommand, environment: environment) {secondResult in
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
    }
    
    @available(iOS 13.0, *)
    func scanWithNfc(environment: CardEnvironment, currentCard: Card, callback: @escaping (TaskEvent<ScanExtendedEvent>) -> Void) {
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
    
    @available(iOS 13.0, *)
    private func readData(with environment: CardEnvironment, completion: @escaping (Result<ReadIssuerExtraDataResponse, TaskError>) -> Void) {
        showProgress()
        let command = ReadIssuerExtraDataCommand(offset: issuerData.count)
        sendCommand(command, environment: environment) {[unowned self] result in
            switch result {
            case .success(let response):
                if let dataSize = response.size {
                    if dataSize == 0 {
                        //no data
                        completion(.success(response))
                        return
                    }
                    self.issuerDataSize = dataSize // initialize only at start
                }
                
                self.issuerData.append(response.issuerData)
                
                if response.issuerDataSignature == nil {
                    self.readData(with: environment, completion: completion)
                } else {
                    self.showProgress()
                    let finalResponse = ReadIssuerExtraDataResponse(cardId: response.cardId,
                                                                    size: response.size,
                                                                    issuerData: self.issuerData,
                                                                    issuerDataSignature: response.issuerDataSignature,
                                                                    issuerDataCounter: response.issuerDataCounter)
                    
                    if let result = finalResponse.verify(publicKey: self.issuerPublicKey!),
                        result == true {
                        self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                        completion(.success(finalResponse))
                    } else {
                        completion(.failure(.verificationFailed))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func showProgress() {
        if issuerDataSize == 0 {
            return
        }
        let progress = Int(round(Float(issuerData.count)/Float(issuerDataSize) * 100.0))
        delegate?.showAlertMessage(Localization.readProgress(progress.description))
    }
}
