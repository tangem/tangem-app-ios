//
//  ReadIssuerDataCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `WriteIssuerDataCommand`.
public struct WriteIssuerDataResponse {
    /// Unique Tangem card ID number
    public let cardId: String
}

/// This command returns 512-byte issuerData field and its issuer’s signature
@available(iOS 13.0, *)
public final class WriteIssuerDataCommand: CommandSerializer {
    public typealias CommandResponse = WriteIssuerDataResponse
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
    public let issuerDataCounter: Data?
    
    /// - Parameters:
    ///   - cardId: CID
    ///   - issuerData: Data to write
    ///   - issuerDataSignature: Signature to write
    ///   - issuerDataCounter: An optional counter that protect issuer data against replay attack. When flag `Protect_Issuer_Data_Against_Replay` set in `SettingsMask`
    /// then this value is mandatory and must increase on each execution of `WriteIssuerDataCommand`.
    public init(cardId: String, issuerData: Data, issuerDataSignature: Data, issuerDataCounter: Data? = nil) {
        self.cardId = cardId
        self.issuerData = issuerData
        self.issuerDataSignature = issuerDataSignature
        self.issuerDataCounter = issuerDataCounter
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        var tlvData = [Tlv(.pin, value: environment.pin1.sha256()),
                       Tlv(.cardId, value: Data(hex: cardId)),
                       Tlv(.issuerData, value: issuerData),
                       Tlv(.issuerDataSignature, value: issuerDataSignature)]
        
        if let counter = issuerDataCounter {
            tlvData.append(Tlv(.issuerDataCounter, value: counter))
        }
        
        let cApdu = CommandApdu(.writeIssuerData, tlv: tlvData)
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> WriteIssuerDataResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return WriteIssuerDataResponse(cardId: try mapper.map(.cardId))
    }
}
