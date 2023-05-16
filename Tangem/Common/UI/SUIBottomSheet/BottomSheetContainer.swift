//
//  SUIBottomSheetContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSwapping

struct SUIBottomSheetContainer<ContentView: View>: View {
    @ObservedObject private var stateObject: StateObject
    private let settings: Settings
    private let content: () -> ContentView

    // MARK: - Internal

    private let indicatorSize = CGSize(width: 40, height: 4)
    private var opacity: CGFloat {
        max(0, settings.backgroundOpacity * stateObject.dragPercentage)
    }

    init(
        stateObject: StateObject,
        settings: Settings,
        content: @escaping () -> ContentView
    ) {
        self.stateObject = stateObject
        self.settings = settings
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(opacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    hideView {
                        stateObject.viewDidHidden()
                    }
                }

            sheetView
                .transition(.move(edge: .bottom))
                // Fix for black outing the sheet after dismiss externally
                .zIndex(1)

            settings.backgroundColor
                // For hide bottom space when sheet is up
                .frame(height: abs(min(0, stateObject.offset)))
                // Added to hide the line between views
                .offset(y: -1)
        }
        .edgesIgnoringSafeArea(.all)
        .animation(.default, value: opacity)
        .animation(.linear(duration: settings.animationDuration), value: stateObject.offset)
    }

    private var sheetView: some View {
        VStack(spacing: 0) {
            indicator

            content()
                .padding(.bottom, UIApplication.safeAreaInsets.bottom)
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
        .cornerRadius(settings.cornerRadius, corners: [.topLeft, .topRight])
        .readSize { stateObject.contentHeight = $0.height }
        .gesture(dragGesture)
        .offset(y: stateObject.offset)
    }

    private var indicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.secondary)
                .frame(size: indicatorSize)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !stateObject.isDragging {
                    stateObject.isDragging = true
                }

                let dragValue = value.translation.height - stateObject.previousDragTranslation.height
                let locationChange = value.startLocation.y - value.location.y

                if locationChange > 0 {
                    stateObject.offset += dragValue / 3
                } else {
                    stateObject.offset += dragValue
                }

                stateObject.previousDragTranslation = value.translation
            }
            .onEnded { value in
                stateObject.previousDragTranslation = .zero
                stateObject.isDragging = false

                // If swipe was been enough to hide view
                if value.translation.height > settings.distanceToHide {
                    hideView {
                        stateObject.viewDidHidden()
                    }
                    // Otherwise set the view to default state
                } else {
                    stateObject.offset = 0
                }
            }
    }

    // MARK: - Methods

    func hideView(completion: @escaping () -> Void) {
        stateObject.offset = UIScreen.main.bounds.height

        DispatchQueue.main.asyncAfter(deadline: .now() + settings.animationDuration) {
            completion()
        }
    }

    func showView() {
        stateObject.offset = 0
    }
}

// MARK: - Settings

extension SUIBottomSheetContainer {
    struct Settings {
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let backgroundOpacity: CGFloat
        let distanceToHide: CGFloat
        let animationDuration: Double

        init(
            cornerRadius: CGFloat = 16,
            backgroundColor: Color = Colors.Background.secondary,
            backgroundOpacity: CGFloat = 0.5,
            distanceToHide: CGFloat = UIScreen.main.bounds.height * 0.1,
            animationDuration: Double = 0.35
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.backgroundOpacity = backgroundOpacity
            self.distanceToHide = distanceToHide
            self.animationDuration = animationDuration
        }
    }
}

// MARK: - StateObject

extension SUIBottomSheetContainer {
    class StateObject: ObservableObject {
        @Published var contentHeight: CGFloat = UIScreen.main.bounds.height / 2
        @Published var isDragging: Bool = false
        @Published var previousDragTranslation: CGSize = .zero
        @Published var offset: CGFloat = UIScreen.main.bounds.height

        public var dragPercentage: CGFloat {
            let visibleHeight = contentHeight - offset
            let percentage = visibleHeight / contentHeight
            return max(0, percentage)
        }

        public var viewDidHidden: () -> Void = {}
    }
}

// MARK: - Previews

struct SUIBottomSheetContainer_Previews: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = SwappingApproveCoordinator()

        var body: some View {
            ZStack {
                Color.green
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $coordinator.item) {
                        SwappingPermissionView(viewModel: $0)
                    }
            }
        }
    }

    class SwappingApproveCoordinator: ObservableObject, SwappingApproveRoutable, SwappingPermissionRoutable {
        @Published var item: SwappingPermissionViewModel?

        func toggleItem() {
            let isShowing = item != nil

            if !isShowing {
                item = SwappingPermissionViewModel(
                    inputModel: SwappingPermissionInputModel(fiatFee: 1.45, transactionData: .mock),
                    transactionSender: TransactionSenderMock(),
                    coordinator: self
                )
            } else {
                item = nil
            }
        }

        func didSendApproveTransaction(transactionData: TangemSwapping.SwappingTransactionData) {}
        func userDidCancel() {
            item = nil
        }
    }

    static var previews: some View {
        StatableContainer()
    }
}
