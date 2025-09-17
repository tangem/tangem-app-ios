//
//  ReorderableGroupedSection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct ReorderableGroupedSection<
    ReorderableModel: Identifiable,
    ReorderableContent: View,
    StaticModel: Identifiable,
    StaticContent: View,
    Footer: View,
    Header: View
>: View {
    // MARK: Dependencies

    @State private var reorderableModels: [ReorderableModel]
    private let reorderableContent: (ReorderableModel) -> ReorderableContent

    private let staticModels: [StaticModel]
    private let staticContent: (StaticModel) -> StaticContent

    private let header: () -> Header
    private let footer: () -> Footer

    private var settings: GroupedSection<
        ReorderableModel,
        ReorderableContent,
        Footer,
        Header,
        EmptyView
    >.Settings = .init()

    // MARK: State

    @State private var reorderableRowHeights: [ReorderableModel.ID: CGFloat] = [:]

    // MARK: Init

    public init(
        reorderableModels: [ReorderableModel],
        staticModels: [StaticModel],
        @ViewBuilder reorderableContent: @escaping (ReorderableModel) -> ReorderableContent,
        @ViewBuilder staticContent: @escaping (StaticModel) -> StaticContent,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
    ) {
        self.reorderableModels = reorderableModels
        self.reorderableContent = reorderableContent

        self.staticModels = staticModels
        self.staticContent = staticContent

        self.header = header
        self.footer = footer
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: GroupedSectionConstants.footerSpacing) {
            VStack(alignment: settings.contentAlignment, spacing: 0) {
                header()
                    .padding(.horizontal, settings.horizontalPadding)
                    .padding(.bottom, settings.interItemSpacing)

                reorderableList

                staticItemsView
            }
            .padding(.vertical, settings.innerContentPadding)
            .background(
                settings.backgroundColor
                    .matchedGeometryEffect(settings.backgroundGeometryEffect)
            )
            .cornerRadiusContinuous(GroupedSectionConstants.defaultCornerRadius)

            footer()
                .padding(.horizontal, settings.horizontalPadding)
        }
    }

    // MARK: Reorderable content

    private var reorderableList: some View {
        ZStack {
            reorderableModelsView
                .hidden()

            List {
                ForEach(reorderableModels) { model in
                    makeListItem(from: model)
                }
                .if(reorderableModels.count > 1) {
                    $0.onMove { from, to in
                        reorderableModels.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .frame(height: reorderableRowHeights.values.reduce(0, +))
            .scrollDisabledBackport(true)
        }
    }

    /// Mikhail Andreev - we need this to exactly set List's height because
    /// it is impossible to somehow make List hug according to its content
    private var reorderableModelsView: some View {
        ForEach(reorderableModels) { model in
            makeListItem(from: model)
                .readGeometry(\.frame.height) {
                    reorderableRowHeights[model.id] = $0
                }
        }
    }

    private func makeListItem(from model: ReorderableModel) -> some View {
        reorderableContent(model)
            .listRowSeparator(.hidden)
            .padding(.horizontal, settings.horizontalPadding)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Static content

    private var staticItemsView: some View {
        ForEach(staticModels) { model in
            staticContent(model)
                .padding(.horizontal, settings.horizontalPadding)
        }
    }
}
