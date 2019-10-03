//
//  Task.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public enum TaskError: Error {
    case unknownStatus(sw: UInt16)
}


@available(iOS 13.0, *)
public protocol Task {
    associatedtype TaskResult
    associatedtype TaskCommand: Command
    
    var cardReader: CardReader {get set}
    
    init(cardReader: CardReader, delegate: CardManagerDelegate)
    func run(with environment: CardEnvironment, completion: @escaping (TaskResult) -> Void )
}

@available(iOS 13.0, *)
extension Task {
    func executeCommand(_ command: TaskCommand, environment: CardEnvironment, completion: @escaping (CompletionResult<TaskResult>) -> Void) {
        let commandApdu = command.serialize(with: environment)
        cardReader.send(command: commandApdu) { commandResult in
            switch commandResult {
            case .success(let responseApdu):
                guard let status = responseApdu.status else {
                    completion(.failure(TaskError.unknownStatus(sw: responseApdu.sw)))
                    return
                }
                
                switch status {
                    
                case .processCompleted:
                    <#code#>
                case .pinsNotChanged:
                    <#code#>
                case .invalidParams:
                    <#code#>
                case .errorProcessingCommand:
                    <#code#>
                case .invalidState:
                    <#code#>
                case .insNotSupported:
                    <#code#>
                case .needEcryption:
                    <#code#>
                case .needPause:
                    <#code#>
                case .pin1Changed:
                    <#code#>
                case .pin2Changed:
                    <#code#>
                case .pin3Changed:
                    <#code#>
                }
                
                //completion(.success())
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
