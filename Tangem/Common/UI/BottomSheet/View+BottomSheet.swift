//
//  View+BottomSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func bottomSheet<Content: View>(isPresented: Binding<Bool>,
                                    viewModelSettings: BottomSheetSettings,
                                    @ViewBuilder contentView: @escaping () -> Content) -> some View {
        self.modifier(BottomSheetModifier(isPresented: isPresented, viewModelSettings: viewModelSettings, contentView: contentView))
    }

    func bottomSheet<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                        viewModelSettings: BottomSheetSettings,
                                                        @ViewBuilder content: @escaping (Item) -> Content) -> some View {
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

    func resizableBottomSheet<Content: ResizableSheetView>(isPresented: Binding<Bool>,
                                                           viewModelSettings: BottomSheetSettings,
                                                           @ViewBuilder contentView: @escaping () -> Content) -> some View {
        self.modifier(ResizableBottomSheetModifier(isPresented: isPresented, viewModelSettings: viewModelSettings, contentView: contentView))
    }
}
