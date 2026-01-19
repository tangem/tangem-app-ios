//
//  LearnView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PromotionView: View {
    @ObservedObject private var viewModel: PromotionViewModel

    init(viewModel: PromotionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            WebView(url: viewModel.url, headers: viewModel.headers, urlActions: viewModel.urlActions)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseTextButton(action: viewModel.close)
                    }
                }
        }
    }
}

struct PromotionView_Preview: PreviewProvider {
    static let viewModel = PromotionViewModel(options: .default, coordinator: PromotionCoordinator())

    static var previews: some View {
        PromotionView(viewModel: viewModel)
    }
}
