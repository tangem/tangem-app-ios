//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias Card = ReadResponse

public enum SigningMethod: Int {
    case signHash = 0
    case signRaw = 1
    case signHashValidatedByIssuer = 2
    case signRawValidatedByIssuer = 3
    case signHashValidatedByIssuerAndWriteIssuerData = 4
    case SignRawValidatedByIssuerAndWriteIssuerData = 5
    case signPos = 6
}

public enum EllipticCurve: String {
    case secp256k1
    case ed25519
}

public enum CardStatus: Int {
    case notPersonalized = 0
    case empty = 1
    case loaded = 2
    case purged = 3
}

public struct ReadResponse: TlvMapable {
    let cardId: String
    let manufacturerName: String
    let status: CardStatus
    let firmwareVersion: String
    let cardPublicKey: String
   // let settingsMask: SettingsMask
    let issuerPublicKey: String
    let curve: EllipticCurve
    let maxSignatures: Int
    let signingMethpod: SigningMethod
    let pauseBeforePin2: Int
    let walletPublicKey: Data
    let walletRemainingSignatures: Int
    let walletSignedHashes: Int
    let health: Int
    let isActivated: Bool
    let activationSeed: Data?
    let paymentFlowVersion: Data
    let userCounter: UInt32
    
    //Card Data
    
    let batchId: Int
    let manufactureDateTime: String
    let issuerName: String
    let blockchainName: String
    let manufacturerSignature: Data?
    //let productMask: ProductMask?
    
    let tokenSymbol: String?
    let tokenContractAddress: String?
    let tokenDecimal: Int?
    
    //Dynamic NDEF

    let remainingSignatures: Int?
    let signedHashes: Int?
    
    public init?(from tlv: [Tlv]) {
        return nil
        //[REDACTED_TODO_COMMENT]
    }
}

@available(iOS 13.0, *)
public class ReadCommand: CommandSerializer {
    public typealias CommandResponse = ReadResponse
    
    let pin1: String
    
    init(pin1: String) {
        self.pin1 = pin1
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        var tlvData = [Tlv(.pin, value: environment.pin1.sha256())]
        if let keys = environment.terminalKeys {
            tlvData.append(Tlv(.terminalPublicKey, value: keys.publicKey))
        }
        
        let cApdu = CommandApdu(.read, tlv: tlvData)
        return cApdu
    }
}
