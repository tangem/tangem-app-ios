//
//  ReadIssuerDataCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `ReadIssuerDataCommand`.
public struct ReadIssuerDataResponse {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Data defined by issuer
    public let issuerData: Data
    /// Issuer’s signature of `issuerData` with `ISSUER_DATA_PRIVATE_KEY`
    /// Version 1.19 and earlier:
    /// Issuer’s signature of SHA256-hashed card ID concatenated with `issuerData`: SHA256(card ID | issuerData)
    /// Version 1.21 and later:
    /// When flag `Protect_Issuer_Data_Against_Replay` set in `SettingsMask` then signature of SHA256-hashed card ID concatenated with
    /// `issuerData`  and `issuerDataCounter`: SHA256(card ID | issuerData | issuerDataCounter)
    public let issuerDataSignature: Data
    /// An optional counter that protect issuer data against replay attack. When flag `Protect_Issuer_Data_Against_Replay` set in `SettingsMask`
    /// then this value is mandatory and must increase on each execution of `WriteIssuerDataCommand`.
    public let issuerDataCounter: Int?
}

/// This command returns 512-byte issuerData field and its issuer’s signature
@available(iOS 13.0, *)
public final class ReadIssuerDataCommand: CommandSerializer {
    public typealias CommandResponse = ReadIssuerDataResponse
    /// Unique Tangem card ID number
    let cardId: String

    public init(cardId: String) {
        self.cardId = cardId
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        let tlvData = [Tlv(.pin, value: environment.pin1.sha256()),
                       Tlv(.cardId, value: Data(hex: cardId))]
        
        let cApdu = CommandApdu(.getIssuerData, tlv: tlvData)
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> ReadIssuerDataResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return ReadIssuerDataResponse(
            cardId: try mapper.map(.cardId),
            issuerData: try mapper.map(.issuerData),
            issuerDataSignature: try mapper.map(.issuerDataSignature),
            issuerDataCounter: try mapper.mapOptional(.issuerDataCounter))
    }
}
