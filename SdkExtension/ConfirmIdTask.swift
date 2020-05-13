//
//  IssueNewIdTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Smart Cash AG. All rights reserved.
//

import Foundation
import TangemSdk

struct ConfirmIdResponse: TlvCodable {
    let issuerData: Data
    let signature: Data
}

@available(iOS 13.0, *)
final class ConfirmIdTask: CardSessionRunnable {
    typealias CommandResponse = ConfirmIdResponse
    weak var card: CardViewModel!
    private let fullname: String
    private let birthDay: Date
    private let gender: String
    private let photo: Data
    private var completion: CompletionResult<ConfirmIdResponse>?
    private var issuerData: Data?
    private let operationQueue = OperationQueue()
    
    public init(fullname: String, birthDay: Date, gender: String, photo: Data) {
        self.fullname = fullname
        self.birthDay = birthDay
        self.gender = gender
        self.photo = photo
    }
    
    deinit {
        print("ConfirmIdTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ConfirmIdResponse>) {
        guard let issuerCard = session.environment.card, let productMask = issuerCard.cardData?.productMask else {
            completion(.failure(.errorProcessingCommand))
            return
        }
        
        let idEngine = card.cardEngine as! ETHIdEngine
        let issuerCardViewModel = CardViewModel(issuerCard)
        
        guard productMask.contains(.idIssuer) || idEngine.card.idIssuerKeys.contains(issuerCardViewModel.walletPublicKey) else {
            completion(.failure(.wrongCard))
            return
        }
        
        session.viewDelegate.showAlertMessage("Constructing transaction")
        
        idEngine.setupInternalEngine(issuerCard: issuerCardViewModel)
        self.completion = completion
        let approvalAddress = idEngine.calculateAddress(from: issuerCardViewModel.walletPublicKey)
        let idCardData = IdCardData(fullname: fullname,
                                    birthDay: birthDay,
                                    gender: gender,
                                    photo: photo,
                                    trustedAddress: approvalAddress)
        issuerData = idCardData.serialize()
        
        guard issuerData != nil else {
            completion(.failure(.errorProcessingCommand))
            return
        }
        
        
        session.viewDelegate.showAlertMessage("Requesting blockchain")
        
        
        let balanceOp = issuerCardViewModel.balanceRequestOperation(onSuccess: { card in
            idEngine.getHashesToSign(idData: idCardData) { data in
                guard let hashes = data else {
                    completion(.failure(.errorProcessingCommand))
                    return
                }
                
                session.viewDelegate.showAlertMessage("Signing")
              //  session.restartPolling()
                self.sign(in: session, hashes: hashes)
            }
        }) { _,_  in
            completion(.failure(.errorProcessingCommand))
        }
        
        operationQueue.addOperation(balanceOp!)
    }
    
    private func sign(in session: CardSession, hashes: [Data]) {
        let signCommand = SignCommand(hashes: hashes)
        signCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                let response = ConfirmIdResponse(issuerData: self.issuerData!, signature: signResponse.signature)
                self.completion?(.success(response))
            case .failure(let error):
                self.completion?(.failure(error))
            }
        }
    }
}
