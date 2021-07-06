// Copyright Keefer Taylor, 2019

import Foundation
import TangemSdk

/// Common prefixes used across Tezos Cryptography.
enum TezosPrefix {
    enum Watermark {
        static let operation: [UInt8] = [ 3 ] // 03
    }
    
    enum Keys {
        enum Ed25519 {
            static let `public`: [UInt8] = [13, 15, 37, 217] // edpk
            static let secret: [UInt8] = [43, 246, 78, 7]    // edsk
            static let seed: [UInt8] = [13, 15, 58, 7] // edsk
            static let signature: [UInt8] = [9, 245, 205, 134, 18] // edsig
        }
        
        enum Secp256r1 {
            static let secret: [UInt8] = [16, 81, 238, 189]  // p2sk
            static let `public`: [UInt8] = [3, 178, 139, 127] // p2pk
            static let signature: [UInt8] = [54, 240, 44, 52] // p2sig
        }
        
        enum Secp256k1 {
            static let `public`: [UInt8] = [3, 254, 226, 86] // sppk
            static let secret: [UInt8] = [17, 162, 224, 201]  // spsk
            static let signature: [UInt8] = [13, 115, 101, 19, 63] // spsig
        }
    }
    
    enum Address {
        static let tz1: [UInt8] = [6, 161, 159] // tz1
        static let tz2: [UInt8] = [6, 161, 161] // tz2
        static let tz3: [UInt8] = [6, 161, 164] // tz3
    }
}


extension TezosPrefix {
    static func publicPrefix(for curve: EllipticCurve) -> Data {
        switch curve {
        case .ed25519:
            return Data(Keys.Ed25519.public)
        case .secp256k1:
            return Data(Keys.Secp256k1.public)
        case .secp256r1:
            return Data(Keys.Secp256r1.public)
        }
    }
    
    static func signaturePrefix(for curve: EllipticCurve) -> Data {
        switch curve {
        case .ed25519:
            return Data(Keys.Ed25519.signature)
        case .secp256k1:
            return Data(Keys.Secp256k1.signature)
        case .secp256r1:
            return Data(Keys.Secp256r1.signature)
        }
    }
    
    static func addressPrefix(for curve: EllipticCurve) -> Data {
        switch curve {
        case .ed25519:
            return Data(Address.tz1)
        case .secp256k1:
            return Data(Address.tz2)
        case .secp256r1:
            return Data(Address.tz3)
        }
    }
}
