//
//  View+BottomSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        viewModelSettings: BottomSheetSettings,
        @ViewBuilder contentView: @escaping () -> Content
    ) -> some View {
        modifier(BottomSheetModifier(isPresented: isPresented, viewModelSettings: viewModelSettings, contentView: contentView))
    }

    func bottomSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        viewModelSettings: BottomSheetSettings,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        let isPresented = Binding {
            item.wrappedValue != nil
        } set: { value in
            if !value {
                item.wrappedValue = nil
            }
        }

        return bottomSheet(isPresented: isPresented, viewModelSettings: viewModelSettings) {
            if let unwrapedItem = item.wrappedValue {
                content(unwrapedItem)
            } else {
                EmptyView()
            }
        }
    }

    func resizableBottomSheet<Item, Content: ResizableSheetView>(
        item: Binding<Item?>,
        viewModelSettings: BottomSheetSettings,
        contentView: @escaping (Item) -> Content
    ) -> some View {
        let isPresented = Binding {
            item.wrappedValue != nil
        } set: { value in
            if !value {
                item.wrappedValue = nil
            }
        }

        return resizableBottomSheet(isPresented: isPresented, viewModelSettings: viewModelSettings) { () -> Content in
            if let unwrapedItem = item.wrappedValue {
                return contentView(unwrapedItem)
            } else {
                return BottomSheetEmptyView() as! Content
            }
        }
    }

    func resizableBottomSheet<Content: ResizableSheetView>(
        isPresented: Binding<Bool>,
        viewModelSettings: BottomSheetSettings,
        contentView: @escaping () -> Content
    ) -> some View {
        modifier(ResizableBottomSheetModifier(isPresented: isPresented, viewModelSettings: viewModelSettings, contentView: contentView))
    }
}
