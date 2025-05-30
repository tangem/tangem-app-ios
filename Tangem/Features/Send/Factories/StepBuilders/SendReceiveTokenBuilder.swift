//
//  ReceiveTokenBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendReceiveTokenBuilder {
    typealias IO = (input: SendReceiveTokenInput, output: SendReceiveTokenOutput)
    typealias ReturnValue = OnrampProvidersViewModel

    private let io: IO
    private let flowKind: SendModel.PredefinedValues.FlowKind

    init(io: IO, flowKind: SendModel.PredefinedValues.FlowKind) {
        self.io = io
        self.flowKind = flowKind
    }
}
