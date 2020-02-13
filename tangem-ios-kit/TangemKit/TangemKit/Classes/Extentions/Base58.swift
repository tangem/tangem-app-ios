//
//  Base58.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import BigInt

public enum Base58String {
    public static let btcAlphabet = [UInt8]("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)
    public static let flickrAlphabet = [UInt8]("123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ".utf8)
    public static let xrpAlphabet = [UInt8]("rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz".utf8)
}

public extension String {

    init(base58Encoding bytes: Data, alphabet: [UInt8] = Base58String.btcAlphabet) {
        var bigInt = BigUInt(bytes)
        let radix = BigUInt(alphabet.count)

        var answer = [UInt8]()
        answer.reserveCapacity(bytes.count)

        while bigInt > 0 {
            let (quotient, modulus) = bigInt.quotientAndRemainder(dividingBy: radix)
            answer.append(alphabet[Int(modulus)])
            bigInt = quotient
        }

        let prefix = Array(bytes.prefix(while: {$0 == 0})).map { _ in alphabet[0] }
        answer.append(contentsOf: prefix)
        answer.reverse()

        self = String(bytes: answer, encoding: String.Encoding.utf8)!
    }

}

extension Data {
    
    init?(base58Decoding string: String, alphabet: [UInt8] = Base58String.xrpAlphabet) {
        var answer = BigUInt(0)
        var j = BigUInt(1)
        let radix = BigUInt(alphabet.count)
        let byteString = [UInt8](string.utf8)

        for ch in byteString.reversed() {
            if let index = alphabet.firstIndex(of: ch) {
                answer = answer + (j * BigUInt(index))
                j *= radix
            } else {
                return nil
            }
        }

        let bytes = answer.serialize()
        self = byteString.prefix(while: { i in i == alphabet[0]}) + bytes
    }

}
