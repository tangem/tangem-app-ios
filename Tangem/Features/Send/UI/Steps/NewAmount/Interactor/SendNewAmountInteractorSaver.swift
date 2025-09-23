//
//  SendNewAmountInteractorSaver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendNewAmountInteractorSaver {
    func update(amount: SendAmount?)

    func captureValue()
    func cancelChanges()
}

class CommonSendNewAmountInteractorSaver: SendNewAmountInteractorSaver {
    private weak var sourceTokenAmountInput: SendSourceTokenAmountInput?
    private weak var sourceTokenAmountOutput: SendSourceTokenAmountOutput?

    private weak var receiveTokenInput: SendReceiveTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?

    var updater: SendAmountExternalUpdater?

    private var captureAmount: SendAmount?
    private var captureToken: SendReceiveTokenType?

    init(
        sourceTokenAmountInput: any SendSourceTokenAmountInput,
        sourceTokenAmountOutput: any SendSourceTokenAmountOutput,
        receiveTokenInput: any SendReceiveTokenInput,
        receiveTokenOutput: any SendReceiveTokenOutput,
    ) {
        self.sourceTokenAmountInput = sourceTokenAmountInput
        self.sourceTokenAmountOutput = sourceTokenAmountOutput
        self.receiveTokenInput = receiveTokenInput
        self.receiveTokenOutput = receiveTokenOutput
    }

    func update(amount: SendAmount?) {
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: amount)
    }

    func captureValue() {
        captureAmount = sourceTokenAmountInput?.sourceAmount.value
        captureToken = receiveTokenInput?.receiveToken
    }

    func cancelChanges() {
        updater?.externalUpdate(amount: captureAmount?.main)
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: captureAmount)

        if let captureToken, captureToken != receiveTokenInput?.receiveToken {
            switch captureToken {
            case .same:
                receiveTokenOutput?.userDidRequestClearSelection()
            case .swap(let receiveToken):
                receiveTokenOutput?.userDidRequestSelect(receiveToken: receiveToken, selected: { _ in })
            }
        }
    }
}
