//
//  TransferTypeFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum TransferTypeFactory {
    @MainActor
    static func makeView(
        orderBuilder: TangemPayOfframpOrderBuilder,
        output: @escaping (TransferTypeViewModel.Output) -> Void
    ) -> some View {
        TransferTypeView(
            viewModel: TransferTypeViewModel(
                orderBuilder: orderBuilder,
                title: Constants.title,
                stepSubtitle: TangemPayOfframpWizardStep.transferType.subtitle(for: orderBuilder.recipient),
                output: output
            )
        )
    }
}

// MARK: - Constants

private extension TransferTypeFactory {
    enum Constants {
        // [REDACTED_TODO_COMMENT]
        static let title = "To personal account"
    }
}
