//
//  Base58.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

public enum Base58String {
    public static let btcAlphabet = [UInt8]("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)
    public static let flickrAlphabet = [UInt8]("123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ".utf8)
    public static let xrpAlphabet = [UInt8]("rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz".utf8)
}

public extension String {
    /**
       * Encodes the given bytes as a base58 string (no checksum is appended).
       *
       * @param input the bytes to encode
       * @return the base58-encoded string
       */
    init(base58 bytes: Data, alphabet: [UInt8] = Base58String.btcAlphabet) {
        if bytes.count == 0 {
            self = ""
        }
        // Count leading zeros.
        let zeros = bytes.prefix { $0 == 0 }.count
        // Convert base-256 digits to base-58 digits (plus conversion to ASCII characters)
        
        var number = bytes
        var answer = Data()
        while zeros < number.count {
            answer.append(alphabet[String.divmod(number: &number, firstDigit: zeros, base: 256, divisor: 58)])
        }
        
        let prefix: [UInt8] = Array(repeating: alphabet[0], count: zeros)
        let encoded = prefix + answer.reversed()
        // Return encoded string (including encoded leading zeros).
        self = String(bytes: encoded, encoding: String.Encoding.utf8)!
    }
    
    /**
     * Divides a number, represented as an array of bytes each containing a single digit
     * in the specified base, by the given divisor. The given number is modified in-place
     * to contain the quotient, and the return value is the remainder.
     *
     * @param number the number to divide
     * @param firstDigit the index within the array of the first non-zero digit
     *        (this is used for optimization by skipping the leading zeros)
     * @param base the base in which the number's digits are represented (up to 256)
     * @param divisor the number to divide by (up to 256)
     * @return the remainder of the division operation
     */
    private static func divmod(number: inout Data, firstDigit: Int, base: Int, divisor: Int) -> Int {
        // this is just long division which accounts for the base of the input digit
        var remainder = 0
        for i in firstDigit..<number.count {
            let digit = Int(number[i] & 0xFF)
            let temp = remainder * base + digit
            number[i] = UInt8(temp / divisor)
            remainder = temp % divisor;
        }
        return remainder
    }    
}


