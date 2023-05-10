//
//  CardHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardHeaderView: View {
    @ObservedObject var viewModel: CardHeaderViewModel
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

final class FakeCardHeaderPreviewProvider: ObservableObject {
    @Published var models: [CardHeaderViewModel] = [
        
    ]
}

struct CardHeaderPreview: View {
    @ObservedObject var provider: FakeCardHeaderPreviewProvider = .init()
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(provider.models.indices
                    , id: \.self, content: { index in
                CardHeaderView(viewModel: provider.models[index])
            })
        }
    }
}

struct CardHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        CardHeaderPreview()
    }
}
