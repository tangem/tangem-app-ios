//
//  CardManager.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation


@available(iOS 13.0, *)
public class CardManager{
//    func test() {
//        let reader = NFCReader()
//        let readCommand = ReadCommand()
//        let task = SingleCommandTask<ReadResponse>(command: readCommand, cardReader: reader, delegate: self)
//        let env = CardEnvironment()
//        task.run(with: env) {readResponse in
//
//        }
//    }
}


@available(iOS 13.0, *)
extension CardManager: CardManagerDelegate {
    public func showSecurityDelay(remainingSeconds: Int) {
        <#code#>
    }
    
    public func requestPin(completion: @escaping () -> CompletionResult<String>) {
        <#code#>
    }
}
