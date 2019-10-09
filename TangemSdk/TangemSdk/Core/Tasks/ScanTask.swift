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
                self.sendCommand(checkWalletCommand) {[unowned self] checkWalletResult in
                    switch checkWalletResult {
                   case .failure(let error):
                    completion(.failure(error))
                    case .success(let checkWalletResponse):
                        let verifyResult = self.verify(readResult: <#T##<<error type>>#>, checkWalletResult: <#T##<<error type>>#>, challenge: <#T##[UInt8]#>)
                        completion(.onVerify(verifyResult))
                    }
                }
            }
        }
        
    }
    
    private func verify(readResult: [CardTag : CardTLV],
                              checkWalletResult: [CardTag : CardTLV],
                              challenge: [UInt8]) -> Bool {
        
        guard let curveId = readResult[.curveId]?.value?.utf8String,
            let curve = EllipticCurve(rawValue: curveId),
            let publicKey = readResult[.walletPublicKey]?.value,
            let salt = checkWalletResult[.salt]?.value,
            let signature = checkWalletResult[.signature]?.value else {
                return false
        }
        let data = challenge + salt
        
//        switch curve {
//        case .secp256k1:
//            let message = data.sha256()
//            var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
//            var sig = secp256k1_ecdsa_signature()
//            var normalized = secp256k1_ecdsa_signature()
//            _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signature)
//            _ = secp256k1_ecdsa_signature_normalize(vrfy, &normalized, sig)
//            var pubkey = secp256k1_pubkey()
//            _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey, 65)
//            let result = secp256k1_ecdsa_verify(vrfy, normalized, message, pubkey)
//            secp256k1_context_destroy(&vrfy)
//            return result
//        case .ed25519:
//            let message = data.sha512()
//            let result = Ed25519.verify(signature, message, publicKey)
//            return result
//        }
    }
}
