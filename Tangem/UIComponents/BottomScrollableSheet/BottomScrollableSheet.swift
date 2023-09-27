//
//  BottomScrollableSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomScrollableSheet<Header: View, Content: View>: View {
    @ViewBuilder private let header: () -> Header
    @ViewBuilder private let content: () -> Content

    @ObservedObject private var stateObject: BottomScrollableSheetStateObject

    private var prefersGrabberVisible = true

    init(
        stateObject: BottomScrollableSheetStateObject,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.stateObject = stateObject
        self.header = header
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                backgroundView

                sheet(proxy: proxy)
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear(perform: stateObject.onAppear)
            .readGeometry(bindTo: stateObject.geometryInfoSubject.asWriteOnlyBinding(.zero))
        }
        .ignoresSafeArea(.keyboard)
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                stateObject.headerDragGesture(onChanged: value)
            }
            .onEnded { value in
                stateObject.headerDragGesture(onEnded: value)
            }
    }

    @ViewBuilder private var backgroundView: some View {
        Color.black
            .opacity(Constants.backgroundViewOpacity * stateObject.progress)
            .ignoresSafeArea()
    }

    @ViewBuilder private var grabber: some View {
        if prefersGrabberVisible {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(size: Constants.grabberSize)
                .padding(.vertical, 8.0)
                .infinityFrame(axis: .horizontal)
        }
    }

    @ViewBuilder private var scrollView: some View {
        ScrollViewRepresentable(delegate: stateObject, content: content)
            .isScrollDisabled(stateObject.scrollViewIsDragging)
    }

    @ViewBuilder
    private func sheet(proxy: GeometryProxy) -> some View {
        VStack(spacing: 0.0) {
            headerView(proxy: proxy)

            scrollView
        }
        .frame(height: stateObject.visibleHeight, alignment: .bottom)
        .cornerRadius(24.0, corners: [.topLeft, .topRight])
    }

    /// Overlay view with reduced hittest area is used here to prevent simultaneous recognition of the drag gesture with the system edge drop gesture.
    @ViewBuilder
    private func gestureOverlayView(proxy: GeometryProxy) -> some View {
        let overlayHeight = max(0.0, stateObject.headerHeight - proxy.safeAreaInsets.bottom)
        Color.clear
            .frame(height: overlayHeight, alignment: .top)
            .contentShape(Rectangle())
            .gesture(dragGesture)
    }

    @ViewBuilder
    private func headerView(proxy: GeometryProxy) -> some View {
        header()
            .overlay(grabber, alignment: .top)
            .readGeometry(\.size.height, bindTo: $stateObject.headerHeight)
            .overlay(gestureOverlayView(proxy: proxy), alignment: .top)
    }
}

// MARK: - Setupable protocol conformance

extension BottomScrollableSheet: Setupable {
    func prefersGrabberVisible(_ visible: Bool) -> Self {
        map { $0.prefersGrabberVisible = visible }
    }
}

// MARK: - Constants

private extension BottomScrollableSheet {
    enum Constants {
        static var backgroundViewOpacity: CGFloat { 0.5 }
        static var grabberSize: CGSize { CGSize(width: 32.0, height: 4.0) }
    }
}
