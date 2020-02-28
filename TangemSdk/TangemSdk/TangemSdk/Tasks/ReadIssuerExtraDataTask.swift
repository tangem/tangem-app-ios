//
//  ReadIssuerExtraDataTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class ReadIssuerExtraDataTask: Task<ReadIssuerExtraDataResponse> {
    private var issuerPublicKey: Data?
    private var callback: ((TaskEvent<ReadIssuerExtraDataResponse>) -> Void)?
    
    private var issuerData = Data()
    private var issuerDataSize = 0
    private var curve: EllipticCurve!
    
    public init(issuerPublicKey: Data? = nil) {
        self.issuerPublicKey = issuerPublicKey
    }
    
    override public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<ReadIssuerExtraDataResponse>) -> Void) {
        guard let curve = currentCard?.curve, let issuerPublicKeyFromCard = currentCard?.issuerPublicKey else {
            reader.stopSession(errorMessage: TaskError.missingPreflightRead.localizedDescription)
            callback(.completion(TaskError.missingPreflightRead))
            return
        }
        
        self.callback = callback
        self.curve = curve
        if issuerPublicKey == nil {
            issuerPublicKey = issuerPublicKeyFromCard
        }
        
        readData(with: environment)
    }
    
    private func readData(with environment: CardEnvironment) {
        showProgress()
        let command = ReadIssuerExtraDataCommand(offset: issuerData.count)
        sendCommand(command, environment: environment) {[unowned self] result in
            switch result {
            case .success(let response):
                if let dataSize = response.size {
                    if dataSize == 0 { //no data
                        self.reader.stopSession()
                        self.callback?(.event(response))
                        self.callback?(.completion())
                        return
                    } else {
                        self.issuerDataSize = dataSize // initialize only at start
                    }
                }
                
                self.issuerData.append(response.issuerData)
                
                if response.issuerDataSignature == nil {
                    self.readData(with: environment)
                } else {
                    self.showProgress()
                    let finalResponse = ReadIssuerExtraDataResponse(cardId: response.cardId,
                                                                    size: response.size,
                                                                    issuerData: self.issuerData,
                                                                    issuerDataSignature: response.issuerDataSignature,
                                                                    issuerDataCounter: response.issuerDataCounter)
                    
                    if let result = finalResponse.verify(curve: self.curve, publicKey: self.issuerPublicKey!),
                        result == true {
                        self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                        self.reader.stopSession()
                        self.callback?(.event(finalResponse))
                        self.callback?(.completion())
                    } else {
                        self.reader.stopSession(errorMessage: TaskError.verificationFailed.localizedDescription)
                        self.callback?(.completion(.verificationFailed))
                    }
                }
            case .failure(let error):
                self.reader.stopSession(errorMessage: error.localizedDescription)
                self.callback?(.completion(error))
            }
        }
    }
    
    private func showProgress() {
        if issuerDataSize == 0 {
            return
        }
        let progress = Int(round(Float(issuerData.count)/Float(issuerDataSize) * 100.0))
        delegate?.showAlertMessage(Localization.readProgress(progress.description))
    }
}
