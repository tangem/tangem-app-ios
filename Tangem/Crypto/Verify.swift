//
//  Verify.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import Foundation

func verify(saltHex:String, challengeHex:String, signatureArr:[UInt8], publicKeyArr:[UInt8]) -> Bool{
    
    //let publicKeyHex: String = "4C31646554EFD9D927062A49E039B4AC31B35C4A90D5FCF3E862215CD3B84BBF510F9733BD900EDB3FF4C7BA409661A9CFFFDC75528DE0B0D9D6CCBC77A88E6B"
    //let publicKeyArr:[UInt8] = [4,76, 49, 100, 101, 84, 239, 217, 217, 39, 6, 42, 73, 224, 57, 180, 172, 49, 179, 92, 74, 144, 213, 252, 243, 232, 98, 33, 92, 211, 184, 75, 191, 81, 15, 151, 51, 189, 144, 14, 219, 63, 244, 199, 186, 64, 150, 97, 169, 207, 255, 220, 117, 82, 141, 224, 176, 217, 214, 204, 188, 119, 168, 142, 107]
    
    
    //Возьмем Challenge и Salt в формате hex
    //let challengeHex = "99E70D6608DF387CA0009892864B1769"
    //let saltHex = "F066FCF2F62B2EE0AFBFBFBA0221FF47"
    
    //Сделаем конкатинацию, переведем hex в бинарные данные и примениим sha256
    let  inputHex = challengeHex + saltHex
    let inputBinary = dataWithHexString(hex: inputHex)
    guard let shaBinary = sha256(inputBinary) else {
        return false
    }
    let messageHex = shaBinary.hexEncodedString()
    //print("\(messageHex.count)")
    let messageArr = messageHex.asciiHexToData()
    
    //let signaruteHex = "ED5D15ACF50880C2CD1CD9C86248FB890282E3677AF89ABA2CC4988DFA8ED603F1804A2087D28925C658451DB749B502309DCBD6834F6C793D7D211F30D9FA6F"
    //let signatureArr:[UInt8] = [237, 93, 21, 172, 245, 8, 128, 194, 205, 28, 217, 200, 98, 72, 251, 137, 2, 130, 227, 103, 122, 248, 154, 186, 44, 196, 152, 141, 250, 142, 214, 3, 241, 128, 74, 32, 135, 210, 137, 37, 198, 88, 69, 29, 183, 73, 181, 2, 48, 157, 203, 214, 131, 79, 108, 121, 61, 125, 33, 31, 48, 217, 250, 111]
    
   // print("\(signaruteHex.count)")
    var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
    
    var sig = secp256k1_ecdsa_signature()
    var dummy = secp256k1_ecdsa_signature()
    print(secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signatureArr));
    print(secp256k1_ecdsa_signature_normalize(vrfy, &dummy, sig))
    var pubkey = secp256k1_pubkey()
    print(secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKeyArr, 65))
    let result = secp256k1_ecdsa_verify(vrfy, dummy,messageArr! , pubkey)
    print("Result \(result)")
    secp256k1_context_destroy(&vrfy);
    
    
    return result
    
}
