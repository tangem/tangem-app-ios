//
//  RefreshableScrollView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

typealias RefreshCompletionHandler = () -> Void
typealias OnRefresh = (_ completionHandler: @escaping RefreshCompletionHandler) -> Void

// [REDACTED_TODO_COMMENT]
/// Author: The SwiftUI Lab.
/// Full article: https://swiftui-lab.com/scrollview-pull-to-refresh/.
@available(*, deprecated, message: "Will be removed in [REDACTED_INFO]. Place `refreshable` modifier with async func instead of this view")
struct RefreshableScrollView<Content: View>: View {
    let onRefresh: OnRefresh
    let content: Content

    init(
        onRefresh: @escaping OnRefresh,
        @ViewBuilder content: () -> Content
    ) {
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
        }
        .refreshable {
            await refreshAsync()
        }
    }

    @MainActor
    private func refreshAsync() async {
        await withCheckedContinuation { continuation in
            onRefresh {
                continuation.resume()
            }
        }
    }
}

// MARK: - Previews

struct RefreshableScrollViewView_Previews: PreviewProvider {
    struct _ScrollView: View {
        @State private var text = "0"
        @State private var updatesCounter = 0

        var body: some View {
            RefreshableScrollView(onRefresh: { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completion()
                }
            }) {
                VStack {
                    Text("Update counter: \(updatesCounter)")
                    Spacer(minLength: 300)
                    Text("Row 1")
                    Text("Row 2")
                    Text("Row 3")
                }
            }
        }
    }

    static var previews: some View {
        _ScrollView()
            .previewDevice("iPhone 11 Pro Max")
    }
}
