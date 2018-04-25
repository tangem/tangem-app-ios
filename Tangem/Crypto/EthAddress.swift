//
//  EthAddress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 dns user. All rights reserved.
//

import Foundation
import CryptoSwift

func getEthAddress(_ hexWalletPublicKey:String) -> String{
    
    let  hexPublicKey = hexWalletPublicKey
    let  hexPublicKeyWithoutTwoFirstLetters = String(hexPublicKey[hexPublicKey.index(hexPublicKey.startIndex,offsetBy:2)...])
    let binaryCuttPublicKey = dataWithHexString(hex: hexPublicKeyWithoutTwoFirstLetters)
    let keccak = binaryCuttPublicKey.sha3(.keccak256)
    let hexKeccak = keccak.hexEncodedString()
    let cutHexKeccak = String(hexKeccak[hexKeccak.index(hexKeccak.startIndex,offsetBy:24)...])
    let ethAddress = "0x"+cutHexKeccak
    
    
    return ethAddress
}
