//
//  StoriesV2DemoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct StoriesV2DemoView: View {
    @ObservedObject var viewModel: StoriesV2DemoViewModel

    var body: some View {
        List {
            if let statusMessage = viewModel.statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Remote stories") {
                row("All slugs (batch)", request: .remoteBatch)

                ForEach(viewModel.storyIDs, id: \.self) { id in
                    row(id.rawValue, request: .remote(id))
                }
            }
        }
        .navigationTitle("Stories V2 Demo")
        // The player lives in the overlay window, so this fires on real navigation away rather than
        // when a story covers the screen.
        .onDisappear { viewModel.cancel() }
    }

    /// Tapping another row cancels the request in flight, so a hung one never locks the screen.
    private func row(_ title: String, request: StoriesV2DemoViewModel.Request) -> some View {
        Button {
            viewModel.open(request)
        } label: {
            HStack {
                Text(title)

                Spacer()

                if viewModel.loadingRequest == request {
                    Loader()
                        .loaderSize(.size16)
                }
            }
        }
    }
}
