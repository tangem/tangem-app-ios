//
//  TangemFadeDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class TangemFadeDemoViewModel: ObservableObject, Identifiable {}

struct TangemFadeDemoView: View {
    @ObservedObject var viewModel: TangemFadeDemoViewModel

    var body: some View {
        TangemFadeShowcase()
            .navigationBarTitle(Text("TangemFade"))
    }
}
