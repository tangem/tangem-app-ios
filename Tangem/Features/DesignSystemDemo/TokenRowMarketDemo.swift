//
//  TokenRowMarketDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TokenRowMarketDemoViewModel: ObservableObject, Identifiable {}

struct TokenRowMarketDemoView: View {
    @ObservedObject var viewModel: TokenRowMarketDemoViewModel

    var body: some View {
        TokenRowMarketShowcase()
            .navigationBarTitle(Text("TokenRowMarket"))
    }
}
