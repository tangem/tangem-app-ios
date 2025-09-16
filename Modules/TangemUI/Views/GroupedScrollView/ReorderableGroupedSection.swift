//
//  ReorderableGroupedSection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct ReorderableGroupedSection<
    ReorderableModel: Identifiable,
    ReorderableContent: View,
    StaticModel: Identifiable,
    StaticContent: View,
    AfterSeparatorContentModel: Identifiable,
    AfterSeparatorContent: View,
    Footer: View,
    Header: View
>: View {
    // MARK: Dependencies

    @Binding private var reorderableModels: [ReorderableModel]
    private let reorderableContent: (ReorderableModel) -> ReorderableContent

    private let staticModels: [StaticModel]?
    private let staticContent: (StaticModel) -> StaticContent

    private let afterSeparatorContentModels: [AfterSeparatorContentModel]?
    private let contentAfterSeparator: (AfterSeparatorContentModel) -> AfterSeparatorContent

    private let header: Header
    private let footer: Footer

    private var settings: GroupedSection<
        ReorderableModel,
        ReorderableContent,
        Footer,
        Header,
        EmptyView
    >.Settings = .init(interItemSpacing: 8, innerContentPadding: 12)

    // MARK: State

    @State private var reorderableRowSizes: [ReorderableModel.ID: CGSize] = [:]

    // MARK: Init

    public init(
        reorderableModels: Binding<[ReorderableModel]>,
        @ViewBuilder reorderableContent: @escaping (ReorderableModel) -> ReorderableContent,

        staticModels: [StaticModel],
        @ViewBuilder staticContent: @escaping (StaticModel) -> StaticContent,

        afterSeparatorContentModels: [AfterSeparatorContentModel],
        @ViewBuilder contentAfterSeparator: @escaping (AfterSeparatorContentModel) -> AfterSeparatorContent,

        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        _reorderableModels = reorderableModels
        self.reorderableContent = reorderableContent
        self.staticModels = staticModels
        self.staticContent = staticContent
        self.afterSeparatorContentModels = afterSeparatorContentModels
        self.contentAfterSeparator = contentAfterSeparator
        self.header = header()
        self.footer = footer()
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: GroupedSectionConstants.footerSpacing) {
            VStack(alignment: settings.contentAlignment, spacing: 0) {
                header
                    .padding(.horizontal, settings.horizontalPadding)
                    .padding(.top, settings.innerContentPadding)
                    .padding(.bottom, settings.interItemSpacing)

                reorderableList

                staticItemsView

                if let afterSeparatorContentModels {
                    VStack(spacing: 0) {
                        Separator(color: Colors.Stroke.primary)
                            .padding(.horizontal, settings.horizontalPadding)

                        makeContentAfterSeparatorItemsView(models: afterSeparatorContentModels)
                    }
                }
            }
            .background(
                settings.backgroundColor
                    .matchedGeometryEffect(settings.backgroundGeometryEffect)
            )
            .cornerRadiusContinuous(GroupedSectionConstants.defaultCornerRadius)

            footer
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
            .frame(height: reorderableRowSizes.values.map(\.height).reduce(0, +))
            .scrollDisabledBackport(true)
        }
    }

    /// Mikhail Andreev - we need this to exactly set List's height because
    /// it is impossible to somehow make List hug according to its content
    private var reorderableModelsView: some View {
        ForEach(reorderableModels) { model in
            makeListItem(from: model)
                .readGeometry(\.frame.size) {
                    reorderableRowSizes[model.id] = $0
                }
        }
    }

    private func makeListItem(from model: ReorderableModel) -> some View {
        reorderableContent(model)
            .listRowSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .padding(.horizontal, settings.horizontalPadding)
            .padding(.vertical, settings.innerContentPadding)
            .contentShape([.dragPreview], RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Static content

    @ViewBuilder
    private var staticItemsView: some View {
        if let staticModels {
            ForEach(staticModels) { model in
                staticContent(model)
                    .padding(.horizontal, settings.horizontalPadding)
                    .padding(.vertical, settings.innerContentPadding)
            }
        }
    }

    // MARK: Content after separator

    @ViewBuilder
    private func makeContentAfterSeparatorItemsView(models: [AfterSeparatorContentModel]) -> some View {
        ForEach(models) { model in
            contentAfterSeparator(model)
                .padding(.horizontal, settings.horizontalPadding)
                .padding(.vertical, settings.innerContentPadding)
        }
    }
}
