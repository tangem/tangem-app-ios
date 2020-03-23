////
////  ScanTask.swift
////  TangemSdk
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2019 Tangem AG. All rights reserved.
////
//
//import Foundation
///**
// * Events that `CreateWalletTask` returns on completion of its commands.
// * `onCreate(CreateWalletResponse)`: Contains data from a Tangem card after successful completion of `CreateWallet`.
// * `onVerify(Bool)`: Shows whether the Tangem card was verified on completion of `CheckWalletCommand`.  Only if  `verifyWallet` is set to true
// */
//public enum CreateWalletEvent {
//    case onCreate(CreateWalletResponse)
//    case onVerify(Bool)
//}
//
///// Task that allows to read Tangem card and verify its private key.
///// It performs `CreateWallet` and `CheckWalletCommand` if  `verifyWallet` is set to true, subsequently.
//[REDACTED_USERNAME](iOS 13.0, *)
//public final class CreateWalletTask: Task<CreateWalletEvent> {
//    private let verifyWallet: Bool
//    
//    /// Defaul initializer
//    /// - Parameter verifyWallet: If true, `CheckWalletCommand` will be executed right after `CreateWallet`. The event `onVerify(Bool)` will be sent
//    init(verifyWallet: Bool) {
//        self.verifyWallet = verifyWallet
//    }
//    
//    override public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<CreateWalletEvent>) -> Void) {
//        guard let card = currentCard else {
//            reader.stopSession(errorMessage: TaskError.missingPreflightRead.localizedDescription)
//            callback(.completion(TaskError.missingPreflightRead))
//            return
//        }
//        
//        guard let curve = card.curve else {
//            reader.stopSession(errorMessage: TaskError.errorProcessingCommand.localizedDescription)
//            callback(.completion(TaskError.errorProcessingCommand))
//            return
//        }
//        
//        sendCommand(CreateWalletCommand(), environment: environment) {[unowned self] result in
//            switch result {
//            case .success(let createWalletResponse):
//                callback(.event(.onCreate(createWalletResponse)))
//                
//                guard self.verifyWallet else {
//                    callback(.completion())
//                    return
//                }
//                
//                if createWalletResponse.status == .loaded {
//                    self.performCheckWallet(curve: curve, walletPublicKey: createWalletResponse.walletPublicKey, environment: environment, callback: callback)
//                } else {
//                    let error = TaskError.errorProcessingCommand
//                    self.reader.stopSession(errorMessage: error.localizedDescription)
//                    callback(.completion(error))
//                }
//            case .failure(let error):
//                self.reader.stopSession(errorMessage: error.localizedDescription)
//                callback(.completion(error))
//            }
//        }
//    }
//    
//    private func performCheckWallet(curve: EllipticCurve, walletPublicKey: Data, environment: CardEnvironment, callback: @escaping (TaskEvent<CreateWalletEvent>) -> Void) {
//        guard let checkWalletCommand = CheckWalletCommand() else {
//            let error = TaskError.errorProcessingCommand
//            reader.stopSession(errorMessage: error.localizedDescription)
//            callback(.completion(error))
//            return
//        }
//        
//        sendCommand(checkWalletCommand, environment: environment) {[unowned self] checkWalletResult in
//            switch checkWalletResult {
//            case .failure(let error):
//                self.reader.stopSession(errorMessage: error.localizedDescription)
//                callback(.completion(error))
//            case .success(let checkWalletResponse):
//                self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
//                self.reader.stopSession()
//                if let verifyResult = checkWalletResponse.verify(curve: curve, publicKey: walletPublicKey, challenge: checkWalletCommand.challenge) {
//                    callback(.event(.onVerify(verifyResult)))
//                    callback(.completion())
//                } else {
//                    callback(.completion(TaskError.verificationFailed))
//                }
//            }
//        }
//    }
//}
