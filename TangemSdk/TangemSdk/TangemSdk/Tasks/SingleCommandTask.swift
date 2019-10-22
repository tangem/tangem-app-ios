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
    private let commandSerializer: T
    
    public init(_ commandSerializer: T) {
        self.commandSerializer = commandSerializer
    }
    
    override public func onRun(environment: CardEnvironment, completion: @escaping (TaskEvent<T.CommandResponse>) -> Void) {
        sendCommand(commandSerializer, environment: environment, completion: completion)
    }
}
