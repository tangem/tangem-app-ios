//
//  BottomScrollableSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct BottomScrollableSheet<Header: View, Content: View>: View {
    @ObservedObject private var stateObject: BottomScrollableSheetStateObject
    @ViewBuilder private let header: () -> Header
    @ViewBuilder private let content: () -> Content

    private let backgroundViewOpacity: CGFloat = 0.5
    private let indicatorSize = CGSize(width: 32, height: 4)

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
            .frame(
                width: proxy.size.width,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                alignment: .bottom
            )
            .ignoresSafeArea(.all, edges: .all)
            .onAppear(perform: stateObject.onAppear)
            .preference(
                key: BottomScrollableSheetStateObject.GeometryReaderPreferenceKey.self,
                value: .init(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            )
            .onPreferenceChange(BottomScrollableSheetStateObject.GeometryReaderPreferenceKey.self) { newValue in
                stateObject.geometryInfo = newValue
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
    }

    private var backgroundView: some View {
        Color.black
            .opacity(backgroundViewOpacity * stateObject.percent)
            .ignoresSafeArea(.all)
    }

    private func sheet(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Color.white

            VStack(spacing: 20) {
                headerView(proxy: proxy)

                scrollView(proxy: proxy)
            }
        }
        .frame(height: stateObject.visibleHeight, alignment: .bottom)
        .cornerRadius(28, corners: [.topLeft, .topRight])
    }

    private func headerView(proxy: GeometryProxy) -> some View {
        VStack(spacing: .zero) {
            indicator(proxy: proxy)

            header()
        }
        .readGeometry(\.size.height, bindTo: $stateObject.headerSize)
        .gesture(dragGesture)
    }

    private func indicator(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .center) {
            Capsule(style: .continuous)
                .fill(Color.gray)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
    }

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

public struct BottomScrollableSheet_Preview: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }

    public struct ContentView: View {
        @ObservedObject private var viewModel = ManageTokensSheetViewModel()
        @ObservedObject private var stateObject = BottomScrollableSheetStateObject()
        public init() {}

        public var body: some View {
            ManageTokensSheetView(viewModel: viewModel, stateObject: stateObject) {
                Color.blue
                    .cornerRadius(14)
                    .scaleEffect(abs(1 - stateObject.percent / 10), anchor: .center)
                    .edgesIgnoringSafeArea(.all)
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}
