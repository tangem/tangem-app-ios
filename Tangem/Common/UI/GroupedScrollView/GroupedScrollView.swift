//
//  GroupedScrollView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct GroupedScrollView<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ScrollView {
            stackContent
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var stackContent: some View {
        if #available(iOS 14.0, *) {
            LazyVStack {
                content()
            }
        } else {
            VStack {
                content()
            }
        }
    }
}


struct GroupedScrollView_Previews: PreviewProvider {
    static var previews: some View {
        GroupedScrollView {
            let viewModels = [
                DefaultRowViewModel(title: "details_chat".localized, action: {}),
                DefaultRowViewModel(title: "details_row_title_send_feedback".localized, action: {}),
            ]

            GroupedSection(viewModels) {
                DefaultRowView(viewModel: $0)
            } footer: {
                DefaultFooterView(title: "Colors.Background.secondary.edgesIgnoringSafeArea(.all)")
            }
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
    }
}
