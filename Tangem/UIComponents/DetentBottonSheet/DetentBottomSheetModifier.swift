//
//  DetentBottomSheetModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// How it works?
/// - When we get `item` we following next steps:
/// 1. Create `BottomSheetContainer` with external `content`
/// 2. Create `UIHostingController` with `rootView` as `sheetContainer`
/// 3. Show `UIController` without animation
/// 4. Show `sheetContainer` with animation
/// - When we should dismiss `bottomSheet` this steps:
/// 1. Hide `sheetContainer` with animation
/// 2. After completion we close `UIController`
@available(iOS 15.0, *)
struct DetentBottomSheetModifier<Item: Identifiable, ContentView: View>: ViewModifier {
    typealias Sheet = DetentBottomSheetContainer<ContentView>

    @Binding private var item: Item?

    @State private var showBottomSheet = false

    private let settings: Sheet.Settings
    private var sheetContent: (Item) -> ContentView

    @State private var controller: UIHostingController<Sheet>?
    private var sheet: Sheet? { controller?.rootView }

    init(
        item: Binding<Item?>,
        settings: Sheet.Settings,
        sheetContent: @escaping (Item) -> ContentView
    ) {
        _item = item
        self.settings = settings
        self.sheetContent = sheetContent
    }

    func body(content: Content) -> some View {
//        if #available(iOS 16.0, *) {
//            content
//                .sheet(isPresented: $showBottomSheet) {
//                    if let item = item {
//                        DetentBottomSheetContainer(settings: settings) {
//                            sheetContent(item)
//                        }
//                        .presentationDragIndicator(.hidden)
//                        .presentationDetents([.medium, .large])
//                    }
//                }.onChange(of: item?.id) { _ in
//                    showBottomSheet = true
//                }
//        } else {
//            content
//                .onChange(of: item?.id) { _ in
//                    sheetPresentationControllerUpdate(item: item)
//                }
//        }
        content
            .onChange(of: item?.id) { _ in
                sheetPresentationControllerUpdate(item: item)
            }
    }

    // MARK: - iOS16 UIKit Implementation BottomSheet

    @available(iOS 16.0, *)
    func sheetUpdate(item: Item?, on content: Content) -> some View {
        content
            .sheet(isPresented: $showBottomSheet) {
                if let item = item {
                    DetentBottomSheetContainer(settings: settings) {
                        sheetContent(item)
                    }
                    .presentationDragIndicator(.hidden)
                    .presentationDetents([.medium])
                }
            }
    }

    // MARK: - iOS15 UIKit Implementation BottomSheet

    func sheetPresentationControllerUpdate(item: Item?) {
        if let item = item {
            let controller = updateUIController(item: item)
            showController(controller)
        } else {
            hideController()
        }
    }

    func updateUIController(item: Item) -> UIHostingController<Sheet> {
        let sheet = DetentBottomSheetContainer(settings: settings) {
            sheetContent(item)
        }

        let controller = UIHostingController<Sheet>(rootView: sheet)
        controller.modalPresentationStyle = .pageSheet
        controller.overrideUserInterfaceStyle = UIApplication.topViewController?.overrideUserInterfaceStyle ?? .unspecified
        controller.view.backgroundColor = .clear

        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large(), .medium()]
            sheet.preferredCornerRadius = settings.cornerRadius
        }

        // Save the controller for dismiss it when it will be needed
        self.controller = controller

        return controller
    }

    func showController(_ controller: UIViewController) {
        UIApplication.modalFromTop(controller, animated: true)
    }

    func hideController() {
        controller?.dismiss(animated: false) {
            // We should deinit controller to avoid unnecessary call update(item:) method
            controller = nil
            item = nil
        }
    }
}
