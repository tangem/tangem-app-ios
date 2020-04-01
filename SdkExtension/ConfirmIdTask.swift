//
//  IssueNewIdTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct ConfirmIdResponse {
    let issuerData: Data
    let signature: Data
}

@available(iOS 13.0, *)
public final class ConfirmIdTask: Task<ConfirmIdResponse> {
    weak var card: CardViewModel!
    private let fullname: String
    private let birthDay: Date
    private let gender: String
    private let photo: Data
    private var callback: ((TaskEvent<ConfirmIdResponse>) -> Void)?
    private var issuerData: Data?
    private let operationQueue = OperationQueue()
    public override var startMessage: String? { return "Hold your iPhone near the Issuer card" }
    
    public init(fullname: String, birthDay: Date, gender: String, photo: Data) {
        self.fullname = fullname
        self.birthDay = birthDay
        self.gender = gender
        self.photo = photo
    }
    
    public override func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<ConfirmIdResponse>) -> Void) {
        guard let issuerCard = currentCard else {
            reader.stopSession(errorMessage: TaskError.missingPreflightRead.localizedDescription)
            callback(.completion(TaskError.missingPreflightRead))
            return
        }
        
     
        let idEngine = card.cardEngine as! ETHIdEngine
        let issuerCardViewModel = CardViewModel(issuerCard)
        
        guard idEngine.trustedKeys.contains(issuerCardViewModel.walletPublicKey) else {
            reader.stopSession(errorMessage: TaskError.wrongCard.localizedDescription)
            callback(.completion(TaskError.wrongCard))
            return
        }
        
        delegate?.showAlertMessage("Constructing transaction")
        
        idEngine.setupInternalEngine(issuerCard: issuerCardViewModel)
        self.callback = callback
        let approvalAddress = idEngine.calculateAddress(from: issuerCardViewModel.walletPublicKey)
        let idCardData = IdCardData(fullname: fullname,
                                    birthDay: birthDay,
                                    gender: gender,
                                    photo: photo,
                                    trustedAddress: approvalAddress)
        issuerData = idCardData.serialize()
        
        guard issuerData != nil else {
            reader.stopSession(errorMessage: TaskError.errorProcessingCommand.localizedDescription)
            callback(.completion(TaskError.errorProcessingCommand))
            return
        }
        
        
        delegate?.showAlertMessage("Requesting blockchain")
        
        let balanceOp = issuerCardViewModel.balanceRequestOperation(onSuccess: {[weak self] card in
            guard let self = self else { return }
            idEngine.getHashesToSign(idData: idCardData) {[weak self] data in
                guard let hashes = data else {
                    self?.reader.stopSession(errorMessage: TaskError.errorProcessingCommand.localizedDescription)
                    callback(.completion(TaskError.errorProcessingCommand))
                    return
                }
                
                self?.delegate?.showAlertMessage("Signing")
                self?.reader.restartPolling()
                self?.sign(hashes, environment: environment)
            }
        }) { _,_  in
            self.reader.stopSession(errorMessage: TaskError.errorProcessingCommand.localizedDescription)
            callback(.completion(TaskError.errorProcessingCommand))
        }
        
        operationQueue.addOperation(balanceOp!)
    }
    
    private func sign(_ hashes: [Data], environment: CardEnvironment) {
        let signCommand = try! SignCommand(hashes: hashes)
        sendCommand(signCommand, environment: environment) {[unowned self] result in
            switch result {
            case .success(let signResponse):
                self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                self.reader.stopSession()
                let response = ConfirmIdResponse(issuerData: self.issuerData!, signature: signResponse.signature)
                self.callback?(.event(response))
                self.callback?(.completion(nil))
            case .failure(let error):
                self.reader.stopSession(errorMessage: error.localizedDescription)
                self.callback?(.completion(error))
            }
        }
    }
}
