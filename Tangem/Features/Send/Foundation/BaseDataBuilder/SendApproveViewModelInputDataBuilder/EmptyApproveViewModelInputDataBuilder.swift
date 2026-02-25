//
//  EmptyApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct EmptyApproveViewModelInputDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeExpressApproveViewModelInput() throws -> ExpressApproveViewModel.Input {
        throw SendApproveViewModelInputDataBuilderError.notSupported
    }
}
