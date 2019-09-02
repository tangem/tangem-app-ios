//  web3swift
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Alex Vlasov. All rights reserved.
//

import Foundation
//import secp256k1_swift

//import EthereumAddress

public class PlainKeystore: AbstractKeystore {
    private var privateKey: Data
    
    public var addresses: [EthereumAddress]?
    
    public var isHDKeystore: Bool = false
    
    public func UNSAFE_getPrivateKeyData(password: String = "", account: EthereumAddress) throws -> Data {
        return self.privateKey
    }
    
    public convenience init?(privateKey: String) {
        guard let privateKeyData = Data.fromHex(privateKey) else {return nil}
        self.init(privateKey: privateKeyData)
    }
    
    public init?(privateKey: Data) {
        guard SECP256K1.verifyPrivateKey(privateKey: privateKey) else {return nil}
        guard let publicKey = Web3.Utils.privateToPublic(privateKey, compressed: false) else {return nil}
        guard let address = Web3.Utils.publicToAddress(publicKey) else {return nil}
        self.addresses = [address]
        self.privateKey = privateKey
    }

}
