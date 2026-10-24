//
//  DesignSystemDemoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemDesignSystemShowcase

@MainActor
final class DesignSystemDemoViewModel: ObservableObject, Identifiable {
    @Published var searchText = ""

    nonisolated init() {}

    private var entries: [DemoEntry] {
        DemoRegistry.entries + [
            DemoEntry("MessageBanner · App notifications", section: .ds3) {
                NotificationBannerCatalogView()
                    .navigationTitle("App notifications")
            },
        ]
    }

    var sections: [Section] {
        DemoEntry.Section.allCases.compactMap { section in
            let items = entries
                .filter { $0.section == section && matchesSearch($0) }
                .sorted { $0.title < $1.title }

            return items.isEmpty ? nil : Section(title: section.title, entries: items)
        }
    }

    private func matchesSearch(_ entry: DemoEntry) -> Bool {
        searchText.isEmpty || entry.title.localizedCaseInsensitiveContains(searchText)
    }
}

extension DesignSystemDemoViewModel {
    struct Section: Identifiable {
        let title: String
        let entries: [DemoEntry]

        var id: String { title }
    }
}
