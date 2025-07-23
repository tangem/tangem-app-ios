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

    func autosave(enabled: Bool)
    func save()
}

class CommonSendNewAmountInteractorSaver: SendNewAmountInteractorSaver {
    private weak var sourceTokenAmountOutput: SendSourceTokenAmountOutput?
    private var cachedAmount: SendAmount?

    private var isAutosaveEnabled: Bool = true

    init(
        sourceTokenAmountInput: any SendSourceTokenAmountInput,
        sourceTokenAmountOutput: SendSourceTokenAmountOutput
    ) {
        cachedAmount = sourceTokenAmountInput.amount

        self.sourceTokenAmountOutput = sourceTokenAmountOutput
    }

    func update(amount: SendAmount?) {
        cachedAmount = amount

        if isAutosaveEnabled {
            save()
        }
    }

    func autosave(enabled: Bool) {
        isAutosaveEnabled = enabled
    }

    func save() {
        sourceTokenAmountOutput?.sourceAmountDidChanged(amount: cachedAmount)
    }
}
