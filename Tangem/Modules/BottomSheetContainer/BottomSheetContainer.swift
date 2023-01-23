//
//  BottomSheetContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetContainer<Item, ContentView: View>: View {
    @Binding private var item: Item?
    private let settings: Settings
    private let content: (Item) -> ContentView

    // MARK: - Internal

    @State private var contentHeight: CGFloat = 400
    @State private var isDragging: Bool = false
    @State private var previousDragTransition: CGSize = .zero
    @State private var offset: CGFloat = UIScreen.main.bounds.height

    private let indicatorSize = CGSize(width: 40, height: 4)

    var dragPercentage: CGFloat {
        let visibleHeight = contentHeight - offset
        let percentage = visibleHeight / contentHeight
        return max(0, percentage)
    }

    var opacity: CGFloat {
        max(0, settings.backgroundOpacity * dragPercentage)
    }

    init(
        item: Binding<Item?>,
        settings: Settings = Settings(),
        content: @escaping (Item) -> ContentView
    ) {
        _item = item
        self.settings = settings
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if let item = item {
                Color.black.opacity(opacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideView(withDelay: false)
                    }

                content(item: item)
                    .transition(.move(edge: .bottom))

                settings.backgroundColor
                    // For hide bottom space when sheet is up
                    .frame(height: abs(min(0, offset)))
                    // Added to hide the line between views
                    .offset(y: -1)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .animation(isDragging ? .interactiveSpring() : .easeInOut(duration: settings.animationDuration))
        .onChange(of: item == nil, perform: didChangeItem)
    }

    private func content(item: Item) -> some View {
        VStack(spacing: 0) {
            indicator

            content(item)
                .padding(.bottom, UIApplication.safeAreaInsets.bottom)
        }
        .zIndex(1)
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
        .cornerRadius(settings.cornerRadius, corners: [.topLeft, .topRight])
        .readSize { contentHeight = $0.height }
        .offset(y: offset)
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
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }

                let dragValue = value.translation.height - previousDragTransition.height
                offset += dragValue / 3

                previousDragTransition = value.translation
            }
            .onEnded { value in
                previousDragTransition = .zero
                isDragging = false

                // If swipe did be enough then hide view
                if value.translation.height > settings.distanceToHide {
                    hideView(withDelay: false)
                    // Otherwise set the view to default state
                } else {
                    offset = 0
                }
            }
    }

    private func didChangeItem(itemIsNil: Bool) {
        if itemIsNil {
            hideView(withDelay: true)
        } else {
            offset = 0
        }
    }

    /// If item we want close view from external place need to await animation completion
    /// Otherwise, like close after swipe we shouldn't wait
    private func hideView(withDelay: Bool) {
        offset = UIScreen.main.bounds.height
        guard item != nil else { return }

        if withDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + settings.animationDuration) {
                item = nil
            }
        } else {
            item = nil
        }
    }

    private func showView() {
        offset = 0
    }
}

extension BottomSheetContainer {
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
            distanceToHide: CGFloat = 100,
            animationDuration: Double = 0.3
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.backgroundOpacity = backgroundOpacity
            self.distanceToHide = distanceToHide
            self.animationDuration = animationDuration
        }
    }
}

struct BottomSheetContainer_Previews: PreviewProvider {
    struct StatableContainer: View {
        @State private var item: SwappingPermissionViewModel? = nil

        var body: some View {
            ZStack {
                Color.green
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((item != nil).description)") {
                    toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $item) {
                        SwappingPermissionView(viewModel: $0)
                    }
            }
        }

        func toggleItem() {
            let isShowing = item != nil

            if !isShowing {
                item = SwappingPermissionViewModel(
                    inputModel: SwappingPermissionInputModel(fiatFee: 1.45, transactionInfo: .mock),
                    transactionSender: TransactionSenderMock(),
                    coordinator: SwappingCoordinator()
                )
            } else {
                item = nil
            }
        }
    }

    static var previews: some View {
        StatableContainer()
    }
}

// MARK: - View +

extension View {
    func bottomSheet<Item, ContentView: View>(
        item: Binding<Item?>,
        settings: BottomSheetContainer<Item, ContentView>.Settings = .init(),
        content: @escaping (Item) -> ContentView
    ) -> some View {
        BottomSheetContainer(item: item, settings: settings, content: content)
    }
}
