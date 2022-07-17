//
//  BottomSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

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
}

struct BottomSheetModifier<ContentView: View>: ViewModifier {
    @Binding private var isPresented: Bool
    @State private var bottomSheetViewController: BottomSheetBaseController?
    private var viewModelSettings: BottomSheetSettings

    private let contentView: () -> ContentView

    init(isPresented: Binding<Bool>,
         viewModelSettings: BottomSheetSettings,
         @ViewBuilder contentView: @escaping () -> ContentView
    ) {
        _isPresented = isPresented
        self.viewModelSettings = viewModelSettings
        self.contentView = contentView
    }

    func body(content: Content) -> some View {
        content
            .valueChanged(value: isPresented, onChange: updatePresentation(_:))
    }

    private func updatePresentation(_ isPresented: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene else { return }

        guard let rootWindow = (windowScene.delegate as? UIWindowSceneDelegate)?.window, let root = rootWindow?.rootViewController else { return }
        var controllerToPresentFrom = root
        while let presented = controllerToPresentFrom.presentedViewController {
            controllerToPresentFrom = presented
        }

        if isPresented {
            bottomSheetViewController = BottomSheetViewController(
                isPresented: $isPresented,
                content: contentView()
            )

            bottomSheetViewController?.preferredSheetSizing = viewModelSettings.bottomSheetSize
            bottomSheetViewController?.preferredSheetCornerRadius = viewModelSettings.cornerRadius
            bottomSheetViewController?.preferredSheetBackdropColor = viewModelSettings.backgroundColor
            bottomSheetViewController?.swipeDownToDismissEnabled = viewModelSettings.swipeDownToDismissEnabled
            bottomSheetViewController?.tapOutsideToDismissEnabled = viewModelSettings.tapOutsideToDismissEnabled

            controllerToPresentFrom.present(bottomSheetViewController!, animated: true)
            viewModelSettings.impactOnShow.play()
        } else {
            bottomSheetViewController?.dismiss(animated: true)
        }
    }
}
