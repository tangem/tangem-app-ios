//
//  LearnView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct PromotionView: View {
    @ObservedObject private var viewModel: PromotionViewModel

    init(viewModel: PromotionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            WebView(url: viewModel.url, headers: viewModel.headers, urlActions: viewModel.urlActions)
                .ignoresSafeArea()
                .navigationBarItems(leading: closeButton)
        }
    }

    private var closeButton: some View {
        Button(Localization.commonClose, action: viewModel.close)
            .foregroundColor(Colors.Button.primary)
    }
}

struct PromotionView_Preview: PreviewProvider {
    static let viewModel = PromotionViewModel(options: .default, coordinator: PromotionCoordinator())

    static var previews: some View {
        PromotionView(viewModel: viewModel)
    }
}
