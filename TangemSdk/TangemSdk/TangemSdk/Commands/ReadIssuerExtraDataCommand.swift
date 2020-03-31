////
////  ReadIssuerExtraDataCommand.swift
////  TangemSdk
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import Foundation
//
///// This enum specifies modes for `ReadIssuerExtraDataCommand` and  `WriteIssuerExtraDataCommand`.
public enum IssuerExtraDataMode: Byte {
    ///This mode is required to read issuer extra data from the card. This mode is required to initiate writing issuer extra data to the card.
    case readOrStartWrite = 1
    
    /// With this mode, the command writes part of issuer extra data
    /// (block of a size [WriteIssuerExtraDataCommand.SINGLE_WRITE_SIZE]) to the card.
    case writePart = 2
    
    /**
     * This mode is used after the issuer extra data was fully written to the card.
     * Under this mode the command provides the issuer signature
     * to confirm the validity of data that was written to card.
     */
    case finalizeWrite = 3
}

public struct ReadIssuerExtraDataResponse: TlvCodable {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Size of all Issuer_Extra_Data field.
    public var size: Int?
    /// Data defined by issuer.
    public var issuerData: Data
    
    /**
     * Issuer’s signature of [issuerData] with Issuer Data Private Key (which is kept on card).
     * Issuer’s signature of SHA256-hashed [cardId] concatenated with [issuerData]:
     * SHA256([cardId] | [issuerData]).
     * When flag [SettingsMask.protectIssuerDataAgainstReplay] set in [SettingsMask] then signature of
     * SHA256-hashed CID Issuer_Data concatenated with and [issuerDataCounter]:
     * SHA256([cardId] | [issuerData] | [issuerDataCounter]).
     */
    public var issuerDataSignature: Data?
    
    /**
     * An optional counter that protect issuer data against replay attack.
     * When flag [SettingsMask.protectIssuerDataAgainstReplay] set in [SettingsMask]
     * then this value is mandatory and must increase on each execution of [WriteIssuerDataCommand].
     */
    public var issuerDataCounter: Int?
    
    public init(cardId: String, size: Int?, issuerData: Data, issuerDataSignature: Data?, issuerDataCounter: Int?) {
        self.cardId = cardId
        self.size = size
        self.issuerData = issuerData
        self.issuerDataSignature = issuerDataSignature
        self.issuerDataCounter = issuerDataCounter
    }
    
    public func verify(publicKey: Data) -> Bool? {
        guard let signature = issuerDataSignature else {
            return nil
        }
        
        let verifier = IssuerDataVerifier()
        return verifier.verify(cardId: cardId,
                               issuerData: issuerData,
                               issuerDataCounter: issuerDataCounter,
                               publicKey: publicKey,
                               signature: signature)
    }
}

/**
 * This command retrieves Issuer Extra Data field and its issuer’s signature.
 * Issuer Extra Data is never changed or parsed from within the Tangem COS. The issuer defines purpose of use,
 * format and payload of Issuer Data. . For example, this field may contain photo or
 * biometric information for ID card product. Because of the large size of Issuer_Extra_Data,
 * a series of these commands have to be executed to read the entire Issuer_Extra_Data.
 */
@available(iOS 13.0, *)
public final class ReadIssuerExtraDataCommand: Command {
    public typealias CommandResponse = ReadIssuerExtraDataResponse
    
    private var issuerPublicKey: Data?
    private var completion: CompletionResult<ReadIssuerExtraDataResponse>?
    private var viewDelegate: CardSessionViewDelegate?
    private var issuerData = Data()
    private var issuerDataSize = 0
    
    public init(issuerPublicKey: Data? = nil) {
        self.issuerPublicKey = issuerPublicKey
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadIssuerExtraDataResponse>) {
        guard let issuerPublicKeyFromCard = session.environment.card?.issuerPublicKey else {
            completion(.failure(.cardError))
            return
        }
        if issuerPublicKey == nil {
            issuerPublicKey = issuerPublicKeyFromCard
        }
        self.completion = completion
        self.viewDelegate = session.viewDelegate
        readData(session, session.environment)
    }
    
    private func readData(_ session: CardSession, _ environment: CardEnvironment) {
        showProgress()
        transieve(in: session) {[unowned self] result in
            switch result {
            case .success(let response):
                if let dataSize = response.size {
                    if dataSize == 0 { //no data
                        self.completion?(.success(response))
                        return
                    } else {
                        self.issuerDataSize = dataSize // initialize only at start
                    }
                }
                
                self.issuerData.append(response.issuerData)
                
                if response.issuerDataSignature == nil {
                    self.readData(session, environment)
                } else {
                    self.showProgress()
                    let finalResponse = ReadIssuerExtraDataResponse(cardId: response.cardId,
                                                                    size: response.size,
                                                                    issuerData: self.issuerData,
                                                                    issuerDataSignature: response.issuerDataSignature,
                                                                    issuerDataCounter: response.issuerDataCounter)
                    
                    if let result = finalResponse.verify(publicKey: self.issuerPublicKey!),
                        result == true {
                        self.completion?(.success(finalResponse))
                    } else {
                        self.completion?(.failure(.verificationFailed))
                    }
                }
            case .failure(let error):
                self.completion?(.failure(error))
            }
        }
    }
    
    private func showProgress() {
        if issuerDataSize == 0 {
            return
        }
        let progress = Int(round(Float(issuerData.count)/Float(issuerDataSize) * 100.0))
        viewDelegate?.showAlertMessage(Localization.readProgress(progress.description))
    }
    
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.cardId, value: environment.card?.cardId)
            .append(.mode, value: IssuerExtraDataMode.readOrStartWrite)
            .append(.offset, value: issuerData.count)
        
        let cApdu = CommandApdu(.readIssuerData, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> ReadIssuerExtraDataResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw SessionError.deserializeApduFailed
        }
        
        let mapper = TlvDecoder(tlv: tlv)
        return ReadIssuerExtraDataResponse(
            cardId: try mapper.decode(.cardId),
            size: try mapper.decodeOptional(.size),
            issuerData: try mapper.decodeOptional(.issuerData) ?? Data(),
            issuerDataSignature: try mapper.decodeOptional(.issuerDataSignature),
            issuerDataCounter: try mapper.decodeOptional(.issuerDataCounter))
    }
}

public class IssuerDataVerifier {
    
    public init() {}
    public func verify(cardId: String,
                       issuerData: Data,
                       issuerDataCounter: Int?,
                       publicKey: Data,
                       signature: Data) -> Bool {
        
        if let verifyResult = verify(cardId: cardId,
                                     issuerData: issuerData,
                                     issuerDataSize: nil,
                                     issuerDataCounter: issuerDataCounter,
                                     publicKey: publicKey,
                                     signature: signature),
            verifyResult == true { return true }
        return false
    }
    
    public func verify(cardId: String,
                       issuerDataSize: Int,
                       issuerDataCounter: Int?,
                       publicKey: Data,
                       signature: Data) -> Bool {
        
        if let verifyResult = verify(cardId: cardId,
                                     issuerData: nil,
                                     issuerDataSize: issuerDataSize,
                                     issuerDataCounter: issuerDataCounter,
                                     publicKey: publicKey,
                                     signature: signature),
            verifyResult == true { return true }
        return false
    }
    
    private func verify(cardId: String,
                        issuerData: Data?,
                        issuerDataSize: Int?,
                        issuerDataCounter: Int?,
                        publicKey: Data,
                        signature: Data) -> Bool? {
        
        let encoder = TlvEncoder()
        var data = Data()
        do {
            data += try encoder.encode(.cardId, value: cardId).value
            if let issuerData = issuerData {
                data += try encoder.encode(.issuerData, value: issuerData).value
            }
            if let counter = issuerDataCounter {
                data += try encoder.encode(.issuerDataCounter, value: counter).value
            }
            if let size = issuerDataSize {
                data += try encoder.encode(.size, value: size).value
            }
        } catch { return nil }
        
        return CryptoUtils.vefify(curve: .secp256k1,
                                  publicKey: publicKey,
                                  message: data,
                                  signature: signature)
    }
    
}
