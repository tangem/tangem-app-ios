//
//  TangemPayWaitlistFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPay

enum TangemPayWaitlistFactory {
    @MainActor
    static func makeView(
        product: TangemPayWaitlistProduct,
        country: String,
        region: String?,
        output: @escaping (TangemPayWaitlistViewModel.Output) -> Void
    ) -> some View {
        TangemPayWaitlistView(
            viewModel: TangemPayWaitlistViewModel(
                product: product,
                country: country,
                region: region,
                service: TangemPayWaitlistServiceBuilder().build(),
                output: output
            )
        )
    }
}
