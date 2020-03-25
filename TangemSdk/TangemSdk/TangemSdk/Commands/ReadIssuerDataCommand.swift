//
//  ReadIssuerDataCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `ReadIssuerDataCommand`.
public struct ReadIssuerDataResponse: TlvCodable {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Data defined by issuer
    public let issuerData: Data
    /**
     * Issuer’s signature of `issuerData` with `ISSUER_DATA_PRIVATE_KEY`
     * Version 1.19 and earlier:
     * Issuer’s signature of SHA256-hashed card ID concatenated with `issuerData`: SHA256(card ID | issuerData)
     * Version 1.21 and later:
     * When flag `Protect_Issuer_Data_Against_Replay` set in `SettingsMask` then signature of SHA256-hashed card ID concatenated with
     * `issuerData`  and `issuerDataCounter`: SHA256(card ID | issuerData | issuerDataCounter)
     */
    public let issuerDataSignature: Data
    /// An optional counter that protect issuer data against replay attack. When flag `Protect_Issuer_Data_Against_Replay` set in `SettingsMask`
    /// then this value is mandatory and must increase on each execution of `WriteIssuerDataCommand`.
    public let issuerDataCounter: Int?
}

/**
 * This command returns 512-byte Issuer Data field and its issuer’s signature.
 * Issuer Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
 * format and payload of Issuer Data. For example, this field may contain information about
 * wallet balance signed by the issuer or additional issuer’s attestation data.
 */
@available(iOS 13.0, *)
public final class ReadIssuerDataCommand: Command {
    public typealias CommandResponse = ReadIssuerDataResponse
    
    public init() {}
    
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.cardId, value: environment.cardId)
        
        let cApdu = CommandApdu(.readIssuerData, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> ReadIssuerDataResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.deserializeApduFailed
        }
        
        let mapper = TlvDecoder(tlv: tlv)
        return ReadIssuerDataResponse(
            cardId: try mapper.decode(.cardId),
            issuerData: try mapper.decode(.issuerData),
            issuerDataSignature: try mapper.decode(.issuerDataSignature),
            issuerDataCounter: try mapper.decodeOptional(.issuerDataCounter))
    }
}
