//
//  BottomScrollableSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

// [REDACTED_TODO_COMMENT]
struct BottomScrollableSheet<Header: View, Content: View>: View {
    @ViewBuilder private let header: () -> Header
    @ViewBuilder private let content: () -> Content

    @ObservedObject private var stateObject: BottomScrollableSheetStateObject

    // [REDACTED_TODO_COMMENT]
    @Environment(\.scenePhase) private var scenePhase

    private let backgroundViewOpacity: CGFloat = 0.5
    private let indicatorSize = CGSize(width: 32, height: 4)

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

    @ViewBuilder
    private var backgroundView: some View {
        Color.black
            .opacity(backgroundViewOpacity * stateObject.percent)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private func sheet(proxy: GeometryProxy) -> some View {
        VStack(spacing: 0.0) {
            headerView(proxy: proxy)
                .overlay(Color.blue.frame(width: 12.0, height: 100.0), alignment: .center) // [REDACTED_TODO_COMMENT]

            scrollView(proxy: proxy)
        }
        .frame(height: stateObject.visibleHeight, alignment: .bottom)
        .cornerRadius(24.0, corners: [.topLeft, .topRight])
    }

    @ViewBuilder
    private func headerView(proxy: GeometryProxy) -> some View {
        header()
            .overlay(indicator(proxy: proxy), alignment: .top)
            .readGeometry(\.size.height, bindTo: $stateObject.headerSize)
            .overlay(
                Color.clear
                    .frame(height: max(0.0, stateObject.headerSize - 34.0), alignment: .top) // [REDACTED_TODO_COMMENT]
                    .contentShape(Rectangle()) // `contentShape` is used here to prevent simultaneous recognition of the drag gesture with the system edge drop gesture
                    .gesture(dragGesture),
                alignment: .top
            )
    }

    @ViewBuilder
    private func indicator(proxy: GeometryProxy) -> some View {
        if prefersGrabberVisible {
            Capsule(style: .continuous)
                .fill(Colors.Icon.inactive)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
                .padding(.vertical, 8.0)
                .infinityFrame(axis: .horizontal)
        }
    }

    @ViewBuilder
    private func scrollView(proxy: GeometryProxy) -> some View {
        ScrollViewRepresentable(delegate: stateObject, content: content)
            .isScrollDisabled(stateObject.scrollViewIsDragging)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                stateObject.headerDragGesture(onChanged: value)
            }
            .onEnded { value in
                stateObject.headerDragGesture(onEnded: value)
            }
    }
}

// MARK: - Setupable protocol conformance

extension BottomScrollableSheet: Setupable {
    func prefersGrabberVisible(_ visible: Bool) -> Self {
        map { $0.prefersGrabberVisible = visible }
    }
}
