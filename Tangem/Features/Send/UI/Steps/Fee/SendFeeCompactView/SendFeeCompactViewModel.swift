//
//  SendFeeCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

class SendFeeCompactViewModel: ObservableObject, Identifiable {
    @Published var feeCompactViewModel: FeeCompactViewModel
    @Published var feeCompactViewIsVisible: Bool

    init(feeCompactViewModel: FeeCompactViewModel = .init(), feeCompactViewIsVisible: Bool = true) {
        self.feeCompactViewModel = feeCompactViewModel
        self.feeCompactViewIsVisible = feeCompactViewIsVisible
    }

    func bind(input: SendFeeInput) {
        feeCompactViewModel.bind(
            selectedFeePublisher: input.selectedFeePublisher,
            supportFeeSelectionPublisher: input.supportFeeSelectionPublisher
        )

        input.shouldShowFeeSelectorRow
            .receiveOnMain()
            .assign(to: &$feeCompactViewIsVisible)
    }
}
