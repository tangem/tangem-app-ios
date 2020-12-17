//
//  SignerUtils.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SignerUtils {
    /// PROD
//    static var signerKeys: KeyPair = {
//        let priv = "F9F4C50636C9E6FC65F92655BD5C21C85A5F6A34DCD0F1E75FCEA1980FE242F5"
//        let pub = "048196AA4B410AC44A3B9CCE18E7BE226AEA070ACC83A9CF67540FAC49AF25129F6A538A28AD6341358E3C4F9963064F7E365372A651D374E5C23CDD37FD099BF2"
//        let keyPairJson = "{\"privateKey\":\"\(priv)\",\"publicKey\":\"\(pub)\"}".data(using: .utf8)
//        let jsonDecoder = JSONDecoder.tangemSdkDecoder
//        let keyPair = try! jsonDecoder.decode(KeyPair.self, from: keyPairJson!)
//        return keyPair
//    }()
    
    
    /// DEV
    static var signerKeys: KeyPair = {
        let priv = "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92"
        let pub = "045F16BD1D2EAFE463E62A335A09E6B2BBCBD04452526885CB679FC4D27AF1BD22F553C7DEEFB54FD3D4F361D14E6DC3F11B7D4EA183250A60720EBDF9E110CD26"
        let keyPairJson = "{\"privateKey\":\"\(priv)\",\"publicKey\":\"\(pub)\"}".data(using: .utf8)
        let jsonDecoder = JSONDecoder.tangemSdkDecoder
        let keyPair = try! jsonDecoder.decode(KeyPair.self, from: keyPairJson!)
        return keyPair
    }()
}
