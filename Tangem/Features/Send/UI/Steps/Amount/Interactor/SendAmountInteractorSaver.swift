//
//  SendAmountInteractorSaver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendAmountInteractorSaver {
    func update(amount: SendAmount?)

    func captureValue()
    func cancelChanges()
}

class CommonSendAmountInteractorSaver: SendAmountInteractorSaver {
    private weak var sourceTokenAmountInput: SendSourceTokenAmountInput?
    private weak var sourceTokenAmountOutput: SendSourceTokenAmountOutput?

    private weak var receiveTokenInput: SendReceiveTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?

    var updater: SendAmountExternalUpdater?

    private var captureAmount: SendAmount?
    private var captureToken: SendReceiveToken?

    init(
        sourceTokenAmountInput: any SendSourceTokenAmountInput,
        sourceTokenAmountOutput: any SendSourceTokenAmountOutput,
        receiveTokenInput: (any SendReceiveTokenInput)?,
        receiveTokenOutput: (any SendReceiveTokenOutput)?,
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
        captureToken = receiveTokenInput?.receiveToken.value
    }

    func cancelChanges() {
        // `main` is crypto or fiat depending on the calculation type at capture time, while `externalUpdate(amount:)`
        // interprets its argument under the *current* type. If the user toggled crypto/fiat before cancelling,
        // the captured number would be re-read in the wrong unit, so restore from the unit-safe crypto value.
        updater?.externalUpdate(cryptoAmount: captureAmount?.crypto)
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: captureAmount)

        if captureToken?.tokenItem != receiveTokenInput?.receiveToken.value?.tokenItem {
            switch captureToken {
            case .none:
                receiveTokenOutput?.userDidRequestClearSelection()
            case .some(let receiveToken):
                receiveTokenOutput?.userDidRequestSelect(receiveTokenItem: receiveToken.tokenItem, selected: { _ in })
            }
        }
    }
}
