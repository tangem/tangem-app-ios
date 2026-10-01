//
//  DesignSystemDemoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemDesignSystemShowcase

struct DesignSystemDemoView: View {
    @ObservedObject var viewModel: DesignSystemDemoViewModel

    @State private var selectedEntry: DemoEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                let sections = viewModel.sections

                if sections.isEmpty {
                    Text("Nothing found")
                        .font(.headline)
                        .padding(.top, 32)
                } else {
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle(Text("Design System Demo"))
        .tangemSearchable(text: $viewModel.searchText, prompt: "Search components", placement: .bottom)
        .navigation(item: $selectedEntry) { entry in
            entry.makeView()
        }
    }

    private func sectionView(_ section: DesignSystemDemoViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(section.entries) { entry in
                MainButton(title: entry.title) {
                    selectedEntry = entry
                }
            }
        }
    }
}
