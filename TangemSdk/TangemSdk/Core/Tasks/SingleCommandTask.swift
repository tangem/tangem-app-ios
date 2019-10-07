//
//  SingleCommandtask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class SingleCommandTask<TCommandSerializer, TResult>: Task where TCommandSerializer: CommandSerializer {
    public typealias TaskResult = TResult
    
    public var cardReader: CardReader?
    public var delegate: CardManagerDelegate?
    
    private let commandSerializer: TCommandSerializer
    
    public init(_ commandSerializer: TCommandSerializer) {
        self.commandSerializer = commandSerializer
    }
    
    public func run(with environment: CardEnvironment, completion: @escaping (CompletionResult<TResult>, CardEnvironment?) -> Void) {
        sendCommand(commandSerializer, environment: environment, completion: completion)
    }
}
