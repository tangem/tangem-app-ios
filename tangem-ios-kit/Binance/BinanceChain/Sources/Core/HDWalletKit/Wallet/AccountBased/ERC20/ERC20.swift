//
//  ERC20.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation

public struct ERC20 {
    public let contractAddress: String
    public let decimal: Int
    public let symbol: String
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - contractAddress: contract address of this erc20 token
    ///   - decimal: decimal specified in a contract
    ///   - symbol: symbol of this erc20 token
    public init(contractAddress: String, decimal: Int, symbol: String) {
        self.contractAddress = contractAddress
        self.decimal = decimal
        self.symbol = symbol
    }
    
    /// Transfer method signiture
    /// function transfer(address _to, uint256 _value) returns (bool success)
    var transferSignature: Data {
        let method = "transfer(address,uint256)"
        return method.data(using: .ascii)!.sha3(.keccak256)[0...3]
    }
    
    var balanceSignature: Data {
        let method = "balanceOf(address)"
        return method.data(using: .ascii)!.sha3(.keccak256)[0...3]
    }
    
    /// Length of 256 bits
    private var lengthOf256bits: Int {
        return 256 / 4
    }
    
    /// Generate transaction data for ERC20 token
    ///
    /// - Parameter:
    ///    - toAddress: address you are transfering to
    ///    - amount: amount to send
    /// - Returns: transaction data
    public func generateSendBalanceParameter(toAddress: String, amount: String) throws -> Data {
        let method = transferSignature.toHexString()
        let address = pad(string: toAddress.stripHexPrefix())
        
        let poweredAmount = try power(amount: amount)
        let amount = pad(string: poweredAmount.serialize().toHexString())
        
        return Data(hex: method + address + amount)
    }
    
    /// Generate get balance data for ERC20 token
    ///
    /// - Parameter:
    ///    - toAddress: address you are transfering to
    ///    - amount: amount to send
    /// - Returns: transaction data
    public func generateGetBalanceParameter(toAddress: String) throws -> Data {
        let method = balanceSignature.toHexString()
        let address = pad(string: toAddress.stripHexPrefix())
        return Data(hex: method + address)
    }
    
    /// Power the amount by the decimal
    ///
    /// - Parameter:
    ///    - amount: amount in string format
    /// - Returns: BigInt value powered by (10 * decimal)
    private func power(amount: String) throws -> BInt {
        let components = amount.split(separator: ".")
        
        // components.count must be 1 or 2. this method accepts only integer or decimal value
        // like 1, 10, 100 or 1.15, 10.7777, 19.9999
        guard components.count == 1 || components.count == 2 else {
            throw HDWalletKitError.contractError(.containsInvalidCharactor(amount))
        }
        
        guard let integer = BInt(String(components[0]), radix: 10) else {
            throw HDWalletKitError.contractError(.containsInvalidCharactor(amount))
        }
        
        let poweredInteger = integer * (BInt(10) ** decimal)
        
        if components.count == 2 {
            let count = components[1].count
            
            guard count <= decimal else {
                throw HDWalletKitError.contractError(.invalidDecimalValue(amount))
            }
            
            guard let digit = BInt(String(components[1]), radix: 10) else {
                throw HDWalletKitError.contractError(.containsInvalidCharactor(amount))
            }
            
            let poweredDigit = digit * (BInt(10) ** (decimal - count))
            return poweredInteger + poweredDigit
        } else {
            return poweredInteger
        }
    }
    
    /// Pad left spaces out of 256bits with 0
    private func pad(string: String) -> String {
        var string = string
        while string.count != lengthOf256bits {
            string = "0" + string
        }
        return string
    }
}
