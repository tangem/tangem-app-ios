//
//  NewsCategoryChipsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemFoundation

struct NewsCategoryChipsView: View {
    let categories: [NewsDTO.Categories.Item]
    @Binding var selectedCategoryId: Int?

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                TangemTabs(
                    data: redesignTabs,
                    selection: redesignSelectionBinding
                )
                .padding(.horizontal, Constants.horizontalChipsViewInset)
            }
            .onChange(of: selectedCategoryId) { _ in
                scrollToSelectedTab(using: proxy)
            }
            .onChange(of: categories.count) { _ in
                scrollToSelectedTab(using: proxy)
            }
        }
    }

    private var redesignTabs: [Tab] {
        var result: [Tab] = [Tab(id: Constants.allCategoryId, title: Localization.commonAll)]
        result.append(contentsOf: categories.map { Tab(id: String($0.id), title: $0.name) })
        return result
    }

    private var redesignSelectionBinding: Binding<Tab> {
        Binding(
            get: { tab(for: selectedCategoryId) },
            set: { newValue in
                if newValue.id == Constants.allCategoryId {
                    selectedCategoryId = nil
                } else {
                    selectedCategoryId = Int(newValue.id)
                }
            }
        )
    }

    private func tab(for categoryId: Int?) -> Tab {
        let id = tabId(for: categoryId)
        return redesignTabs.first { $0.id == id } ?? redesignTabs[0]
    }

    private func tabId(for categoryId: Int?) -> String {
        categoryId.map(String.init) ?? Constants.allCategoryId
    }

    private func scrollToSelectedTab(using proxy: ScrollViewProxy) {
        // The selected id is always fresh via the binding, unlike `categories`, which can be a
        // stale empty snapshot inside `onChange`.
        let targetId = tabId(for: selectedCategoryId)

        // Defer one runloop — on a deeplink the target chip is inserted in this same update and
        // isn't laid out yet, so a synchronous `scrollTo` would find nothing and no-op.
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(targetId, anchor: .center)
            }
        }
    }
}

extension NewsCategoryChipsView {
    enum Constants {
        static let allCategoryId = Localization.commonAll
        static let horizontalChipsViewInset: CGFloat = 16
    }

    fileprivate struct Tab: TangemTabsTextProvider {
        let id: String
        let title: String

        var text: String { title }
    }
}
