//
//  DetentBottomSheetContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct DetentBottomSheetContainer<ContentView: View>: View {
    @ObservedObject private var stateObject: StateObject
    private let settings: Settings
    private let content: () -> ContentView

    // MARK: - Internal

    private let indicatorSize = CGSize(width: 32, height: 4)

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
        sheetView
    }

    private var sheetView: some View {
        VStack(spacing: 0) {
            indicator

            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.backgroundColor)
        .readGeometry(\.size.height, bindTo: $stateObject.contentHeight)
        .offset(y: stateObject.offset)
    }

    private var indicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: indicatorSize)
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }

    // MARK: - Methods

    func hideView(completion: @escaping () -> Void) {
        let duration = settings.animationDuration

        withAnimation(.linear(duration: duration)) {
            stateObject.offset = UIScreen.main.bounds.height
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion()
        }
    }

    func showView() {
        let duration = settings.animationDuration

        withAnimation(.linear(duration: duration)) {
            stateObject.offset = 0
        }
    }
}

// MARK: - Settings

@available(iOS 15.0, *)
extension DetentBottomSheetContainer {
    struct Settings {
        let detents: [UISheetPresentationController.Detent]
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let distanceToHide: CGFloat
        let animationDuration: Double

        init(
            detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
            cornerRadius: CGFloat = 24,
            backgroundColor: Color = Colors.Background.secondary,
            distanceToHide: CGFloat = UIScreen.main.bounds.height * 0.1,
            animationDuration: Double = 0.35
        ) {
            self.detents = detents
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.distanceToHide = distanceToHide
            self.animationDuration = animationDuration
        }
    }
}

// MARK: - StateObject

@available(iOS 15.0, *)
extension DetentBottomSheetContainer {
    class StateObject: ObservableObject {
        @Published var contentHeight: CGFloat = UIScreen.main.bounds.height / 2
        @Published var isDragging: Bool = false
        @Published var offset: CGFloat = UIScreen.main.bounds.height

        public var viewDidHidden: () -> Void = {}
    }
}
