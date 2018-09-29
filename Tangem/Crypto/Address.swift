//
//  Address.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

func getAddress(_ hexWalletPublicKey:String) -> [String]?{
    var Addresses = [String]() // Addresses[0] Bitcoin Main; Addresses[1] Bitcoin TestNet
    
    //let hexPublicKeyTest = "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6"
    //let hexPublicKeyTest = "0406BEB82D849049C87B7A3625A8DBAAF4B73A4DE13CF98D6B20F6B684DC9FE3F618C125D73BD4127CDFB809BB411255C5BB4E15217C0D7E0517CC3AFF7F0E428B"
    
    let hexPublicKey = hexWalletPublicKey
    //Hex String to Binary Data
    let binaryPublicKey = dataWithHexString(hex: hexPublicKey)
    
    //Check Point: Binary Data to Hex String
    //let checkHexPublicKey = binaryPublicKey.hexEncodedString()
    //print("Check \(checkHexPublicKey)")
   
    //сделаем sha256  бинарные данные в бинарные данные
    guard let binaryHash = sha256(binaryPublicKey) else {
        return nil
    }
    
    //Check Point: Binary Data to Hex String
    //let binaryHashToHex = binaryHash.hexEncodedString()
    //Шаг 2 600FFE422B4E00731A59557A5CCA46CC183944191006324A447BDB2D98D4B408
    //print("Шаг 2 \(binaryHashToHex.uppercased())")
    
    
    let binaryRipemd160 = RIPEMD160.hash(message: binaryHash)
    
    //Check Point: Binary Data to Hex String
    //let binaryRipemd160ToHex = binaryRipemd160.hexEncodedString()
    //Шаг 3  010966776006953D5567439E5E39F86A0D273BEE
    //print("Шаг 3 \(binaryRipemd160ToHex.uppercased())")
    
    // "00" - Main
    // "6F" - Test
    let hexRipend160 = "00" + binaryRipemd160.hexEncodedString()
    //Шаг 4   00010966776006953D5567439E5E39F86A0D273BEE
    //print("Шаг 4 \(hexRipend160)")
    
    let binaryExtendedRipemd = dataWithHexString(hex: hexRipend160)
    guard let binaryOneSha = sha256(binaryExtendedRipemd) else {
        return nil
    }
    //Check Point: Binary Data to Hex String
    //let binaryOneShaToHex = binaryOneSha.hexEncodedString()
    //Шаг 5 445C7A8007A93D8733188288BB320A8FE2DEBD2AE1B47F0F50BC10BAE845C094
    //print("Шаг 5 \(binaryOneShaToHex.uppercased())")
    
    guard let binaryTwoSha = sha256(binaryOneSha) else {
        return nil
    }
    //Check Point: Binary Data to Hex String
    let binaryTwoShaToHex = binaryTwoSha.hexEncodedString()
    //Шаг 6    D61967F63C7DD183914A4AE452C9F6AD5D462CE3D277798075B107615C1A8A30
    //print("Шаг 6 \(binaryTwoShaToHex.uppercased())")
    
    let checkHex = String(binaryTwoShaToHex[..<binaryTwoShaToHex.index(binaryTwoShaToHex.startIndex, offsetBy: 8)])
    //Шаг 7    D61967F6
    //print("Шаг 7  \(checkHex)")
    
    
    let addCheckToRipemd = hexRipend160 + checkHex //binary Address
    //Шаг 8    00010966776006953D5567439E5E39F86A0D273BEED61967F6
    //print("Шаг 8 \(addCheckToRipemd)")
    
    let binaryForBase58 = dataWithHexString(hex: addCheckToRipemd)
    let address = String(base58Encoding: binaryForBase58) //Address
    //Шаг 9    16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM
    
    
    let hexRipend1601 = "6F" + binaryRipemd160.hexEncodedString()
    let binaryExtendedRipemd1 = dataWithHexString(hex: hexRipend1601)
    guard let binaryOneSha1 = sha256(binaryExtendedRipemd1) else {
        return nil
    }
    guard let binaryTwoSha1 = sha256(binaryOneSha1) else {
        return nil
    }
    let binaryTwoShaToHex1 = binaryTwoSha1.hexEncodedString()
    let checkHex1 = String(binaryTwoShaToHex1[..<binaryTwoShaToHex1.index(binaryTwoShaToHex1.startIndex, offsetBy: 8)])
    let addCheckToRipemd1 = hexRipend1601 + checkHex1 //binary Address
    let binaryForBase581 = dataWithHexString(hex: addCheckToRipemd1)
    let address1 = String(base58Encoding: binaryForBase581) //Address
    
    
    
    Addresses.append(address)
    Addresses.append(address1)
    
    
    return Addresses
}



