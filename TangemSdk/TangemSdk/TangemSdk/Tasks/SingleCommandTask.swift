////
////  SingleCommandtask.swift
////  TangemSdk
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2019 Tangem AG. All rights reserved.
////
//
//import Foundation
//
///**
//* Allows to perform a single command
//* `TCommand` -  a command that will be performed.
//*/
//[REDACTED_USERNAME](iOS 13.0, *)
//public final class SingleCommandTask<TCommand: Command>: Task<TCommand.CommandResponse> {
//    private let command: TCommand
//    
//    public init(_ command: TCommand) {
//        self.command = command
//    }
//    
//    override public func onRun(environment: CardEnvironment, currentCard: Card?, callback: @escaping (TaskEvent<TCommand.CommandResponse>) -> Void) {
//        sendCommand(command, environment: environment) {[weak self] result in
//            switch result {
//            case .success(let commandResponse):
//                self?.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
//                self?.reader.stopSession()
//                callback(.event(commandResponse))
//                callback(.completion(nil))
//            case .failure(let error):
//                self?.reader.stopSession(errorMessage: error.localizedDescription)
//                callback(.completion(error))
//            }
//        }
//    }
//}
