//
//  SingleCommandtask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class SingleCommandTask<T: CommandSerializer>: Task<T.CommandResponse> {
    private let command: T
    
    public init(_ command: T) {
        self.command = command
    }
    
    override public func onRun(environment: CardEnvironment, callback: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        sendCommand(command, environment: environment) { result in
            switch result {
            case .success(let commandResponse):
                self.delegate?.showAlertMessage(Localization.nfcAlertDefaultDone)
                self.cardReader.stopSession()
                callback(.event(commandResponse))
                callback(.completion(nil))
                self.cardReader.stopSession()
            case .failure(let error):
                self.cardReader.stopSession(errorMessage: error.localizedDescription)
                callback(.completion(error))
            }
        }
    }
}
