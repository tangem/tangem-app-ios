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

    var updater: SendExternalAmountUpdater?

    private var captureAmount: SendAmount?

    init(
        sourceTokenAmountInput: any SendSourceTokenAmountInput,
        sourceTokenAmountOutput: any SendSourceTokenAmountOutput
    ) {
        self.sourceTokenAmountInput = sourceTokenAmountInput
        self.sourceTokenAmountOutput = sourceTokenAmountOutput
    }

    func update(amount: SendAmount?) {
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: amount)
    }

    func captureValue() {
        captureAmount = sourceTokenAmountInput?.amount
    }

    func cancelChanges() {
        updater?.externalUpdate(amount: captureAmount?.main)
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: captureAmount)
    }
}
