//
//  BalanceVerificationOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class BalanceVerificationOperation: Operation {
    
    var saltHex = ""
    var challengeHex = ""
    var signatureArr = [UInt8]()
    var publicKeyArr = [UInt8]()
    
    var completion: (Bool) -> Void
    
    init(saltHex: String, challengeHex: String, signatureArr: [UInt8], publicKeyArr: [UInt8], completion: @escaping (Bool) -> Void) {
        self.saltHex = saltHex
        self.challengeHex = challengeHex
        self.signatureArr = signatureArr
        self.publicKeyArr = publicKeyArr
        self.completion = completion
    }
    
    override func main() {
        let inputHex = challengeHex + saltHex
        let inputBinary = dataWithHexString(hex: inputHex)
        
        guard let shaBinary = sha256(inputBinary) else {
            DispatchQueue.main.async {
                self.completion(false)
            }
            return
        }
        
        let messageHex = shaBinary.hexEncodedString()
        let messageArr = messageHex.asciiHexToData()
        
        var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
        
        var sig = secp256k1_ecdsa_signature()
        var dummy = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signatureArr)
        _ = secp256k1_ecdsa_signature_normalize(vrfy, &dummy, sig)
        var pubkey = secp256k1_pubkey()
        _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKeyArr, 65)
        let result = secp256k1_ecdsa_verify(vrfy, dummy, messageArr! , pubkey)
        
        secp256k1_context_destroy(&vrfy);
        
        guard !isCancelled else {
            return
        }
        
        DispatchQueue.main.async {
            self.completion(result)
        }
    }
    
}
