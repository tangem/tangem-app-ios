//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum ScanResult {
    case onRead(Card)
    case onVerify(Bool)
    case failure(Error)
}


@available(iOS 13.0, *)
public class ScanTask: Task<ScanResult> {
    override public func run(with environment: CardEnvironment, completion: @escaping (ScanResult) -> Void) {
        super.run(with: environment, completion: completion)
        
        let readCommand = ReadCommand(pin1: environment.pin1)
        sendCommand(readCommand) {[unowned self] readResult in
            switch readResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let readResponse):
                completion(.onRead(readResponse))
                
                guard let challenge = CryptoUtils.generateRandomBytes(count: 16) else {
                    completion(.failure(TaskError.generateChallengeFailed))
                    return
                }
                
                let checkWalletCommand = CheckWalletCommand(pin1: environment.pin1, cardId: readResponse.cardId, challenge: challenge)
                self.sendCommand(checkWalletCommand) {checkWalletResult in
                    switch checkWalletResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let checkWalletResponse):
                        let verifyResult = CryptoUtils.vefify(curve: readResponse.curve,
                                                              publicKey: readResponse.walletPublicKey,
                                                              message: challenge + checkWalletResponse.salt,
                                                              signature: checkWalletResponse.walletSignature)
                        completion(.onVerify(verifyResult))
                    }
                }
            }
        }
    }
}
