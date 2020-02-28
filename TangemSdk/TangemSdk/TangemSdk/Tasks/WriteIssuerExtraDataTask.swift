//
//  WriteIssuerExtraDataTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class WriteIssuerExtraDataTask: Task<WriteIssuerDataResponse> {
    
    private var issuerData: Data
    private let startingSignature: Data
    private let finalizingSignature: Data
    private var issuerPublicKey: Data?
    private var issuerDataCounter: Int?
    private var callback: ((TaskEvent<WriteIssuerDataResponse>) -> Void)?
    
    private var mode: IssuerExtraDataMode = .readOrStartWrite
    private var offset: Int = 0
    
    public init(issuerData: Data, issuerPublicKey: Data? = nil, startingSignature: Data, finalizingSignature: Data, issuerDataCounter: Int? = nil) {
        self.issuerData = issuerData
        self.issuerPublicKey = issuerPublicKey
        self.startingSignature = startingSignature
        self.finalizingSignature = finalizingSignature
        self.issuerDataCounter = issuerDataCounter
    }
    
    override public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<WriteIssuerDataResponse>) -> Void) {
        guard let curve = currentCard?.curve,
            let settingsMask = currentCard?.settingsMask,
            let issuerPublicKeyFromCard = currentCard?.issuerPublicKey,
            let cardId = environment.cardId else {
                reader.stopSession(errorMessage: TaskError.missingPreflightRead.localizedDescription)
                callback(.completion(TaskError.missingPreflightRead))
                return
        }
        
        if settingsMask.contains(.protectIssuerDataAgainstReplay) && issuerDataCounter == nil {
            reader.stopSession(errorMessage: TaskError.missingCounter.localizedDescription)
            callback(.completion(.missingCounter))
            return
        }
        
        guard verify(with: cardId,
                     issuerPublicKey: issuerPublicKey ?? issuerPublicKeyFromCard,
                     curve: curve) else {
                        reader.stopSession(errorMessage: TaskError.verificationFailed.localizedDescription)
                        callback(.completion(.verificationFailed))
                        return
        }
        
        self.callback = callback
        
        writeData(with: environment)
    }
    
    private func writeData(with environment: CardEnvironment) {
        showProgress()
        sendCommand(buildCommand(), environment: environment) {[unowned self] result in
            switch result {
            case .success(let response):
                switch self.mode {
                case .readOrStartWrite:
                    self.mode = .writePart
                    self.writeData(with: environment)
                case .writePart:
                    self.offset += WriteIssuerExtraDataCommand.singleWriteSize
                    if self.offset >= self.issuerData.count {
                        self.mode = .finalizeWrite
                    }
                    self.writeData(with: environment)
                case .finalizeWrite:
                    self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                    self.reader.stopSession()
                    self.callback?(.event(response))
                    self.callback?(.completion())
                }
            case .failure(let error):
                self.reader.stopSession(errorMessage: error.localizedDescription)
                self.callback?(.completion(error))
            }
        }
    }
    
    private func buildCommand() -> WriteIssuerExtraDataCommand {
        switch mode {
        case .readOrStartWrite:
            return WriteIssuerExtraDataCommand(issuerData: issuerData,
                                               issuerDataSignature: startingSignature,    
                                               mode: mode,
                                               offset: 0,
                                               issuerDataCounter: issuerDataCounter)
        case .writePart:
            return WriteIssuerExtraDataCommand(issuerData: issuerData[calculateChunk()],
                                               issuerDataSignature: Data(),
                                               mode: mode,
                                               offset: offset,
                                               issuerDataCounter: issuerDataCounter)
        case .finalizeWrite:
            return WriteIssuerExtraDataCommand(issuerData: Data(),
                                               issuerDataSignature: finalizingSignature,
                                               mode: mode,
                                               offset: 0)
        }
    }
    
    private func calculateChunk() -> Range<Int> {
        let bytesLeft = issuerData.count - offset
        let to = min(bytesLeft, WriteIssuerExtraDataCommand.singleWriteSize)
        return offset..<offset + to
    }
    
    private func verify(with cardId: String, issuerPublicKey: Data, curve: EllipticCurve) -> Bool {
        let startingVerifierResult = IssuerDataVerifier().verify(cardId: cardId,
                                                                 issuerDataSize: issuerData.count,
                                                                 issuerDataCounter: issuerDataCounter,
                                                                 curve: curve,
                                                                 publicKey: issuerPublicKey,
                                                                 signature: startingSignature)
        
        let finalizingVerifierResult = IssuerDataVerifier().verify(cardId: cardId,
                                                                   issuerData: issuerData,
                                                                   issuerDataCounter: issuerDataCounter,
                                                                   curve: curve,
                                                                   publicKey: issuerPublicKey,
                                                                   signature: finalizingSignature)
        
        return startingVerifierResult && finalizingVerifierResult
    }
    
    private func showProgress() {
        guard mode == .writePart else {
               return
           }
        let progress = Int(round(Float(offset)/Float(issuerData.count) * 100.0))
        delegate?.showAlertMessage(Localization.readProgress(progress.description))
       }
}
