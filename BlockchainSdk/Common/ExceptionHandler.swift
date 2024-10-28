//
//  ExceptionHandler.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExceptionHandlerOutput {
    func handleAPISwitch(currentHost: String, nextHost: String, message: String)
}

public final class ExceptionHandler {
    // MARK: - Static

    public static let shared: ExceptionHandler = .init()

    // MARK: - Properties

    private var outputs: [ExceptionHandlerOutput] = []

    // MARK: - Configuration

    public func append(output: ExceptionHandlerOutput) {
        outputs.append(output)
    }

    // MARK: - Handle

    func handleAPISwitch(currentHost: String, nextHost: String, message: String) {
        outputs.forEach { output in
            output.handleAPISwitch(
                currentHost: currentHost,
                nextHost: nextHost,
                message: message
            )
        }
    }
}
