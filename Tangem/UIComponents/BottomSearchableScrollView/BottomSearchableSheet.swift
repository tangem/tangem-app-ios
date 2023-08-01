//
//  BottomSearchableSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct BottomSearchableSheet<Header: View, Content: View>: View {
    @ObservedObject var coordinator: BottomSearchableSheetCoordinator
    @ObservedObject var stateObject: BottomSearchableSheetStateObject

    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    private let handHeight: CGFloat = 20
    private let indicatorSize = CGSize(width: 32, height: 4)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(min(stateObject.percent, 0.4))
                    .ignoresSafeArea(.all)

                sheet(proxy: proxy)

                NavHolder()
                    .bottomSheet(item: $coordinator.bottomSheet) {
                        BottomSheetContainer_Previews.BottomSheetView(viewModel: $0)
                    }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                alignment: .bottom
            )
            .ignoresSafeArea(.all, edges: .all)
            .onAppear {
                stateObject.onAppear()
            }
            .preference(
                key: BottomSearchableSheetStateObject.GeometryReaderPreferenceKey.self,
                value: .init(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            )
            .onPreferenceChange(BottomSearchableSheetStateObject.GeometryReaderPreferenceKey.self) { newValue in
                stateObject.geometryInfo = newValue
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
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
        .gesture(dragGesture(proxy: proxy))
    }

    private func indicator(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .center) {
            Capsule(style: .continuous)
                .fill(Color.gray)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
        }
        .frame(width: proxy.size.width, height: handHeight)
    }

    private func scrollView(proxy: GeometryProxy) -> some View {
        ScrollViewRepresentable(delegate: stateObject, content: content)
            .isScrollDisabled(stateObject.scrollViewIsDragging)
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                stateObject.headerDragGesture(onChanged: value)
            }
            .onEnded { value in
                stateObject.headerDragGesture(onEnded: value)
            }
    }
}

public struct BottomSearchableSheet_Preview: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }

    public struct ContentView: View {
        private var coordinator = BottomSearchableSheetCoordinator()
        @ObservedObject
        private var stateObject = BottomSearchableSheetStateObject()

        @State private var data: [String]
        @State private var text: String = ""

        public init() {
            data = [
                "8720887669",
                "6039443653",
                "9850878178",
                "2523434461",
                "3225165235",
                "1571481152",
                "1419738515",
                "1791877061",
                "5591228645",
                "7682196099",
                "2348297778",
                "1844539876",
                "5201470631",
                "5056640801",
                "5362434881",
                "4262364184",
                "3147960099",
                "4494423305",
                "0400480229",
                "8439651677",
                "3395831241",
                "8836341113",
                "1716823902",
                "8318130334",
                "5781367105",
                "2350841586",
                "0766309218",
                "9862777806",
                "2237740770",
                "7678295553",
                "1360253958",
                "5927156193",
                "0163843915",
                "1203085116",
                "8007135186",
                "7245306292",
                "5962971496",
                "7859817739",
                "5876523700",
                "0203416494",
                "3030361471",
                "1304408513",
                "3486010173",
                "9205641047",
                "3058042191",
                "2301414836",
                "6824028479",
                "6495209954",
                "2427762150",
                "2973843019",
            ]
        }

        public var body: some View {
            ZStack(alignment: .bottom) {
                Color.blue
                    .cornerRadius(14)
                    .scaleEffect(abs(1 - stateObject.percent / 10), anchor: .center)
                    .edgesIgnoringSafeArea(.all)

                BottomSearchableSheet(coordinator: coordinator, stateObject: stateObject) {
                    TextField("Placeholder", text: $text)
                        .frame(height: 46)
                        .padding(.horizontal, 12)
                        .background(Colors.Field.primary)
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                } content: {
                    LazyVStack(spacing: .zero) {
                        ForEach(data.filter { text.isEmpty ? true : $0.contains(text.lowercased()) }, id: \.self) { index in
                            Button {
                                coordinator.toggleItem()
                                data[data.firstIndex(of: index)!] += "-1"
                            } label: {
                                Text(index)
                                    .font(.title3)
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.all)
                            }

                            Color.black
                                .opacity(0.2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}
