//
//  BottomScrollableSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetModifier<
    Item,
    SheetHeader,
    SheetContent,
    SheetOverlay
>: ViewModifier where Item: Identifiable, SheetHeader: View, SheetContent: View, SheetOverlay: View {
    let item: Item

    @ViewBuilder let sheetHeader: (_ item: Item) -> SheetHeader
    @ViewBuilder let sheetContent: (_ item: Item) -> SheetContent
    @ViewBuilder let sheetOverlay: (_ item: Item) -> SheetOverlay

    @StateObject private var stateObject = BottomScrollableSheetStateObject()

    @Environment(\.bottomScrollableSheetConfiguration) private var configuration

    func body(content: Content) -> some View {
        ZStack {
            UIAppearanceBoundaryContainerView(boundaryMarker: TestTest.self, scale: stateObject.scale) {
                content
                    .cornerRadius(14.0)
                    .edgesIgnoringSafeArea(.all)
            }
            .cornerRadius(14.0)
            .edgesIgnoringSafeArea(.all)
            .layoutPriority(1000.0)
            .printSize("size_content")

            BottomScrollableSheet(
                stateObject: stateObject,
                header: sheetHeader(item),
                content: sheetContent(item),
                overlay: sheetOverlay(item)
            )
            .prefersGrabberVisible(configuration.prefersGrabberVisible)
            .isHiddenWhenCollapsed(configuration.isHiddenWhenCollapsed)
            .allowsHitTesting(configuration.allowsHitTesting)
            .environment(\.bottomScrollableSheetStateController, stateObject)
//            .infinityFrame()
            .printSize("size_sheet")
        }
        .printSize("size_zstack")
        .background { Color.black.ignoresSafeArea(edges: .vertical) }
    }
}

// MARK: - Convenience extensions

extension View {
    /// An overload that supports `overlay` view
    func bottomScrollableSheet<Item, Header, Content, Overlay>(
        item: Item,
        @ViewBuilder header: @escaping (_ item: Item) -> Header,
        @ViewBuilder content: @escaping (_ item: Item) -> Content,
        @ViewBuilder overlay: @escaping (_ item: Item) -> Overlay
    ) -> some View where Item: Identifiable, Header: View, Content: View, Overlay: View {
        modifier(
            BottomScrollableSheetModifier(
                item: item,
                sheetHeader: header,
                sheetContent: content,
                sheetOverlay: overlay
            )
        )
        .id(item.id)
    }

    /// An overload without `overlay` view support.
    func bottomScrollableSheet<Item, Header, Content>(
        item: Item,
        @ViewBuilder header: @escaping (_ item: Item) -> Header,
        @ViewBuilder content: @escaping (_ item: Item) -> Content
    ) -> some View where Item: Identifiable, Header: View, Content: View {
        return bottomScrollableSheet(
            item: item,
            header: header,
            content: content,
            overlay: { _ in EmptyView() }
        )
    }
}

private class TestTest: UIViewController {}
