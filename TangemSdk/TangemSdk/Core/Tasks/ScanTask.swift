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
    case usedCancelled
    case failure(TaskError)
}


@available(iOS 13.0, *)
public final class ScanTask: Task<ScanEvent> {
    override public func onRun(environment: CardEnvironment, completion: @escaping (ScanEvent, CardEnvironment) -> Void) {
        let readCommand = ReadCommand(pin1: environment.pin1)
        sendCommand(readCommand, environment: environment) {readResult, environment  in
            switch readResult {
            case .failure(let error):
                self.cardReader.stopSession()
                completion(.failure(error), environment)
            case .success(let readResponse):
                completion(.onRead(readResponse), environment)
                
                guard readResponse.status == .loaded else {
                    return
                }
                
                guard let curve = readResponse.curve, let publicKey = readResponse.walletPublicKey else {
                    completion(.failure(TaskError.cardError), environment)
                    return
                }
                
                guard let challenge = CryptoUtils.generateRandomBytes(count: 16) else {
                    self.cardReader.stopSession()
                    completion(.failure(TaskError.vefificationFailed), environment)
                    return
                }
                
                let checkWalletCommand = CheckWalletCommand(pin1: environment.pin1, cardId: readResponse.cardId, challenge: challenge)
                self.sendCommand(checkWalletCommand, environment: environment) {checkWalletResult, environment in
                    self.cardReader.stopSession()
                    switch checkWalletResult {
                    case .failure(let error):
                        completion(.failure(error), environment)
                    case .success(let checkWalletResponse):
                        if let verifyResult = CryptoUtils.vefify(curve: curve,
                                                                 publicKey: publicKey,
                                                                 message: challenge + checkWalletResponse.salt,
                                                                 signature: checkWalletResponse.walletSignature) {
                            completion(.onVerify(verifyResult), environment)
                        } else {
                            completion(.failure(TaskError.vefificationFailed), environment)
                        }
                        
                    case .userCancelled:
                        completion(.usedCancelled, environment)
                    }
                }
            case .userCancelled:
                  completion(.usedCancelled, environment)
            }
        }
    }
}
