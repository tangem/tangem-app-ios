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
 */
@available(iOS 13.0, *)
public final class WriteIssuerExtraDataCommand: Command {
    public typealias CommandResponse = WriteIssuerExtraDataResponse
    
    public static let singleWriteSize = 1524
    
    private var mode: IssuerExtraDataMode = .readOrStartWrite
    private var offset: Int = 0
    private let issuerData: Data
    private var issuerPublicKey: Data?
    private let startingSignature: Data
    private let finalizingSignature: Data
    private let issuerDataCounter: Int?
    
    private var completion: CompletionResult<WriteIssuerExtraDataResponse>?
    private var viewDelegate: SessionViewDelegate?
    
    /// Initializer
    /// - Parameters:
    ///   - issuerData: Data provided by issuer
    ///   - issuerPublicKey: Optional key for check data validity. If nil, `issuerPublicKey` from current card will be used
    ///   - startingSignature:  Issuer’s signature with Issuer Data Private Key of `cardId`, `issuerDataCounter` (if flags Protect_Issuer_Data_Against_Replay and
    ///    Restrict_Overwrite_Issuer_Extra_Data are set in `SettingsMask`) and size of `issuerData`.
    ///   - finalizingSignature: Issuer’s signature with Issuer Data Private Key of `cardId`, `issuerData` and `issuerDataCounter` (the latter one only if flags Protect_Issuer_Data_Against_Replay
    ///   and Restrict_Overwrite_Issuer_Extra_Data are set in `SettingsMask`).
    ///   - issuerDataCounter: An optional counter that protect issuer data against replay attack.
    public init(issuerData: Data, issuerPublicKey: Data? = nil, startingSignature: Data, finalizingSignature: Data, issuerDataCounter: Int? = nil) {
        self.issuerData = issuerData
        self.issuerPublicKey = issuerPublicKey
        self.startingSignature = startingSignature
        self.finalizingSignature = finalizingSignature
        self.issuerDataCounter = issuerDataCounter
    }
    
    deinit {
           print("WriteIssuerExtraDataCommand deinit")
       }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<WriteIssuerExtraDataResponse>) {
        guard let settingsMask = session.environment.card?.settingsMask,
            let cardId = session.environment.card?.cardId else {
                completion(.failure(.cardError))
                return
        }
        
        if settingsMask.contains(.protectIssuerDataAgainstReplay) && issuerDataCounter == nil {
            completion(.failure(.missingCounter))
            return
        }
        
        if issuerPublicKey == nil {
            issuerPublicKey = session.environment.card?.issuerPublicKey
        }
        
        guard issuerPublicKey != nil else {
            completion(.failure(.missingIssuerPublicKey))
            return
        }
        
        guard verify(with: cardId) else {
            completion(.failure(.verificationFailed))
            return
        }
        
        self.completion = completion
        self.viewDelegate = session.viewDelegate
        writeData(session)
    }
    
    private func writeData(_ session: CardSession) {
        showProgress()
        transieve(in: session) {result in
            switch result {
            case .success(let response):
                switch self.mode {
                case .readOrStartWrite:
                    self.mode = .writePart
                    self.writeData(session)
                case .writePart:
                    self.offset += WriteIssuerExtraDataCommand.singleWriteSize
                    if self.offset >= self.issuerData.count {
                        self.mode = .finalizeWrite
                    }
                   self.writeData(session)
                case .finalizeWrite:
                    self.viewDelegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                    self.completion?(.success(response))
                }
            case .failure(let error):
                self.completion?(.failure(error))
            }
        }
    }
    
    private func calculateChunk() -> Range<Int> {
        let bytesLeft = issuerData.count - offset
        let to = min(bytesLeft, WriteIssuerExtraDataCommand.singleWriteSize)
        return offset..<offset + to
    }
    
    private func verify(with cardId: String) -> Bool {
        let startingVerifierResult = IssuerDataVerifier().verify(cardId: cardId,
                                                                 issuerDataSize: issuerData.count,
                                                                 issuerDataCounter: issuerDataCounter,
                                                                 publicKey: issuerPublicKey!,
                                                                 signature: startingSignature)
        
        let finalizingVerifierResult = IssuerDataVerifier().verify(cardId: cardId,
                                                                   issuerData: issuerData,
                                                                   issuerDataCounter: issuerDataCounter,
                                                                   publicKey: issuerPublicKey!,
                                                                   signature: finalizingSignature)
        
        return startingVerifierResult && finalizingVerifierResult
    }
    
    private func showProgress() {
        guard mode == .writePart else {
            return
        }
        let progress = Int(round(Float(offset)/Float(issuerData.count) * 100.0))
        viewDelegate?.showAlertMessage(Localization.writeProgress(progress.description))
    }
    
    public func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
            .append(.cardId, value: environment.card?.cardId)
            .append(.mode, value: mode)
        
        switch mode {
        case .readOrStartWrite:
            try tlvBuilder
                .append(.size, value: issuerData.count)
                .append(.issuerDataSignature, value: startingSignature)
            
            if let counter = issuerDataCounter {
                try tlvBuilder.append(.issuerDataCounter, value: counter)
            }
            
        case .writePart:
            try tlvBuilder
                .append(.issuerData, value: issuerData[calculateChunk()])
                .append(.offset, value: offset)
            
        case .finalizeWrite:
            try tlvBuilder.append(.issuerDataSignature, value: finalizingSignature)
        }
        
        let cApdu = CommandApdu(.writeIssuerData, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: SessionEnvironment, from responseApdu: ResponseApdu) throws -> WriteIssuerExtraDataResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw SessionError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return WriteIssuerDataResponse(cardId: try decoder.decode(.cardId))
    }
}
