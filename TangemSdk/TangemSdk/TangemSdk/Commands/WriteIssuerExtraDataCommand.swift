//
//  WriteIssuerExtraDataCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public typealias WriteIssuerExtraDataResponse = WriteIssuerDataResponse

/**
 * This command writes Issuer Extra Data field and its issuer’s signature.
 * Issuer Extra Data is never changed or parsed from within the Tangem COS.
 * The issuer defines purpose of use, format and payload of Issuer Data.
 * For example, this field may contain a photo or biometric information for ID card products.
 * Because of the large size of Issuer_Extra_Data, a series of these commands have to be executed
 * to write entire Issuer_Extra_Data.
 * @param issuerData Data provided by issuer.
 * @param startingSignature Issuer’s signature with Issuer Data Private Key of [cardId],
 * [issuerDataCounter] (if flags Protect_Issuer_Data_Against_Replay and
 * Restrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]) and size of [issuerData].
 * @param finalizingSignature Issuer’s signature with Issuer Data Private Key of [cardId],
 * [issuerData] and [issuerDataCounter] (the latter one only if flags Protect_Issuer_Data_Against_Replay
 * andRestrict_Overwrite_Issuer_Extra_Data are set in [SettingsMask]).
 * @param issuerDataCounter An optional counter that protect issuer data against replay attack.
 */
@available(iOS 13.0, *)
public final class WriteIssuerExtraDataCommand: CommandSerializer {
    public typealias CommandResponse = WriteIssuerExtraDataResponse
    
    public static let singleWriteSize = 1524
    
    private let mode: IssuerExtraDataMode
    private let offset: Int
    private let issuerData: Data
    private let issuerDataSignature: Data
    private let issuerDataCounter: Int?
    
    public init(issuerData: Data, issuerDataSignature: Data, mode: IssuerExtraDataMode, offset: Int, issuerDataCounter: Int? = nil) {
        self.issuerData = issuerData
        self.issuerDataSignature = issuerDataSignature
        self.mode = mode
        self.offset = offset
        self.issuerDataCounter = issuerDataCounter
    }
    
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.cardId, value: environment.cardId)
            .append(.mode, value: mode)
        
        switch mode {
        case .readOrStartWrite:
            try tlvBuilder
                .append(.size, value: issuerData.count)
                .append(.issuerDataSignature, value: issuerDataSignature)
            
            if let counter = issuerDataCounter {
                try tlvBuilder.append(.issuerDataCounter, value: counter)
            }
            
        case .writePart:
            try tlvBuilder
                .append(.issuerData, value: issuerData)
                .append(.offset, value: offset)
            
        case .finalizeWrite:
            try tlvBuilder.append(.issuerDataSignature, value: issuerDataSignature)
        }
        
        let cApdu = CommandApdu(.writeIssuerData, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> WriteIssuerExtraDataResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return WriteIssuerDataResponse(cardId: try mapper.map(.cardId))
    }
}
