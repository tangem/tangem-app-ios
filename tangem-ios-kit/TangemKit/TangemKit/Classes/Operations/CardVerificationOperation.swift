////
////  SignatureVerificationOperation.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2018 Smart Cash AG. All rights reserved.
////
//
//import Foundation
//import GBAsyncOperation
//import Sodium
//
//class SignatureVerificationOperation: GBAsyncOperation {
//
//    var curve: EllipticCurve
//    var saltHex: String
//    var challengeHex: String
//    var signatureArr: [UInt8]
//    var publicKeyArr: [UInt8]
//
//    var completion: (Bool) -> Void
//
//    init(curve: EllipticCurve = .secp256k1, saltHex: String, challengeHex: String, signatureArr: [UInt8], publicKeyArr: [UInt8], completion: @escaping (Bool) -> Void) {
//        self.curve = curve
//        self.saltHex = saltHex
//        self.challengeHex = challengeHex
//        self.signatureArr = signatureArr
//        self.publicKeyArr = publicKeyArr
//
//        self.completion = completion
//    }
//
//    override func main() {
//        let inputHex = challengeHex + saltHex
//        let inputBinary = dataWithHexString(hex: inputHex)
//
//        guard let shaBinary = sha256(inputBinary), let messageArr = shaBinary.hexEncodedString().asciiHexToData() else {
//            completeOperationWith(result: false)
//            return
//        }
//
//        switch curve {
//        case .secp256k1:
//            secp256(message: messageArr)
//        case .ed25519:
//            ed25519(message: messageArr)
//        }
//    }
//
//    func secp256(message: [UInt8]) {
//
//        var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
//
//        var sig = secp256k1_ecdsa_signature()
//        var dummy = secp256k1_ecdsa_signature()
//        _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signatureArr)
//        _ = secp256k1_ecdsa_signature_normalize(vrfy, &dummy, sig)
//        var pubkey = secp256k1_pubkey()
//        _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKeyArr, 65)
//        let result = secp256k1_ecdsa_verify(vrfy, dummy, message, pubkey)
//
//        secp256k1_context_destroy(&vrfy)
//
//        completeOperationWith(result: result)
//    }
//
//    func ed25519(message: [UInt8]) {
//        let result = Ed25519.verify(signatureArr, message, publicKeyArr)
//        completeOperationWith(result: result)
//    }
//
//    func completeOperationWith(result: Bool) {
//        DispatchQueue.main.async {
//            self.completion(result)
//        }
//    }
//
//}
