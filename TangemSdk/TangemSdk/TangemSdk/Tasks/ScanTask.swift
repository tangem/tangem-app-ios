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

@available(iOS 13.0, *)
public final class ScanTask: Task<ScanEvent> {
    override public func onRun(environment: CardEnvironment, completion: @escaping (TaskEvent<ScanEvent>) -> Void) {
        let readCommand = ReadCommand(pin1: environment.pin1)
        sendCommand(readCommand, environment: environment) { readResult in
            switch readResult {
            case .failure(let error):
                self.cardReader.stopSession()
                completion(.failure(error))
            case .event(let readResponse):
                completion(.event(.onRead(readResponse)))
                guard readResponse.status == .loaded else {
                    return
                }
                
                guard let curve = readResponse.curve, let publicKey = readResponse.walletPublicKey else {
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
                        } else {
                            completion(.failure(TaskError.vefificationFailed))
                        }
                    case .success(let environment):
                        completion(.success(environment))
                    }
                }
            case .success(_):
                break
            }
        }
    }
}
