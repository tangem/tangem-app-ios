//
//  EmptyApproveViewModelInputDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct EmptyApproveViewModelInputDataBuilder: SendApproveViewModelInputDataBuilder {
    func makeApproveFlowFactory() throws -> ApproveFlowFactory {
        throw SendApproveViewModelInputDataBuilderError.notSupported
    }
}
