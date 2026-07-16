//
//  SendBaseViewAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendBaseViewAnalyticsLogger {
    func logSendBaseViewOpened()

    func logRequestSupport()

    func logMainActionButton(type: SendMainButtonType, flow: SendFlowActionType)
    func logCloseButton(stepType: SendStepType, isAvailableToAction: Bool)
}
