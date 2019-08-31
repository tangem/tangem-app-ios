//
//  EthereumTransaction.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import web3swift
import BigInt

extension EthereumTransaction {
    public func encodeForSend(chainID: BigUInt? = nil) -> Data? {
        
        let encodeV = chainID == nil ? self.v :
            self.v - 27 + chainID! * 2 + 35
        
        let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value, self.data, encodeV, self.r, self.s] as [AnyObject]
        return RLP.encode(fields)
    }
    
    init?(amount: BigUInt, fee: BigUInt, targetAddress: String, nonce: BigUInt, v: BigUInt = 0, r: BigUInt = 0, s: BigUInt = 0) {
        
        let gasLimit = BigUInt(21000)
        let gasPrice = fee / gasLimit
        
        guard let ethAddress = EthereumAddress(targetAddress) else {
            return nil
        }
        
        self.init( nonce: nonce,
                   gasPrice: gasPrice,
                   gasLimit: gasLimit,
                   to: ethAddress,
                   value: amount,
                   data: Data(),
                   v: v,
                   r: r,
                   s: s)
    }
}
