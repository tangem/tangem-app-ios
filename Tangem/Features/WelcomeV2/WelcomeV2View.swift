//
//  WelcomeV2View.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct WelcomeV2View: View {
    @ObservedObject var viewModel: WelcomeV2ViewModel

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay {
                Text("Welcome V2")
                    .foregroundColor(.white)
            }
    }
}

// MARK: - Previews

#Preview {
    WelcomeV2View(viewModel: WelcomeV2ViewModel(coordinator: WelcomeV2Coordinator()))
}
