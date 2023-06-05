//
//  LearnView.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import SwiftUI

struct PromotionView: View {
    @ObservedObject private var viewModel: PromotionViewModel

    init(viewModel: PromotionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        WebView(url: viewModel.url, headers: viewModel.headers, urlActions: viewModel.urlActions)
    }
}

struct PromotionView_Preview: PreviewProvider {
    static let viewModel = PromotionViewModel(options: .default, coordinator: PromotionCoordinator())

    static var previews: some View {
        PromotionView(viewModel: viewModel)
    }
}
