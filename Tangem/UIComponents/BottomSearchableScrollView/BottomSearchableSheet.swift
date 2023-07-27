//
//  BottomSearchableSheet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct BottomSearchableSheet<Content: View>: View {
    @Binding var searchText: String
    @Binding var percent: CGFloat {
        didSet {
            print("percent ->>", percent)
        }
    }

    @ViewBuilder let content: () -> Content

    @State private var state: SheetState = .bottom {
        didSet {
            print("state ->>", state)
        }
    }

    @State private var visibleHeight: CGFloat = 0 {
        didSet {
            print("visibleHeight ->>", visibleHeight)
            percent = (visibleHeight - headerSize - 34) / 500
        }
    }

    @State private var isKeyboardVisible: Bool = false
    @State private var scrollViewIsDragging: Bool = false {
        didSet {
            print("scrollViewIsDragging", scrollViewIsDragging)
        }
    }

    @State private var scrollViewStartDraggingOffset: CGPoint = .zero {
        didSet {
            print("scrollViewStartDraggingOffset", scrollViewStartDraggingOffset)
        }
    }
    @State private var headerSize: CGFloat = 44
    @State private var contentOffset: CGPoint = .zero
    @State private var contentSize: CGSize = .zero

    private let handHeight: CGFloat = 20
    private let indicatorSize = CGSize(width: 32, height: 4)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(min(percent, 0.4))
                    .ignoresSafeArea(.all)

                sheet(proxy: proxy)
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height + proxy.safeAreaInsets.vertical,
                alignment: .bottom
            )
            .border(Color.orange, width: 3)
            .ignoresSafeArea(.all, edges: .all)
            .onAppear {
                updateToState(proxy: proxy)
            }
            .onReceive(keyboardPublisher) { newIsKeyboardVisible in
                print("Is keyboard visible? ", newIsKeyboardVisible)
                isKeyboardVisible = newIsKeyboardVisible
                if newIsKeyboardVisible {
                    state = .top
                    updateToState(proxy: proxy)
                }
            }
        }
    }

    func sheet(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Color.white

            VStack(spacing: 8) {
                headerView(proxy: proxy)

                scrollView(proxy: proxy)
            }
        }
        .frame(height: visibleHeight, alignment: .bottom)
//        .cornerRadius(28, corners: [.topLeft, .topRight])
        .cornerRadius(28)
        .border(Color.orange, width: 3)
    }

    func headerView(proxy: GeometryProxy) -> some View {
        VStack(spacing: .zero) {
            indicator

            TextField("Placeholder", text: $searchText)
                .frame(height: 46)
                .padding(.horizontal)
                .background(Color.secondary.opacity(0.4))
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .readGeometry(\.size.height, bindTo: $headerSize)
        .gesture(dragGesture(proxy: proxy))
    }

    private var indicator: some View {
        ZStack(alignment: .center) {
            Capsule(style: .continuous)
                .fill(Color.gray)
                .frame(width: indicatorSize.width, height: indicatorSize.height)
        }
        .frame(maxWidth: .infinity)
        .frame(height: handHeight)
        .background(Color.purple.opacity(0.5))
    }

    private var axes: Axis.Set {
        return scrollViewIsDragging ? [] : .vertical
    }

    func scrollView(proxy: GeometryProxy) -> some View {
        ScrollView(axes, showsIndicators: true) {
            VStack(spacing: .zero) {
                offsetReader

                content()
                    .readGeometry(\.size, bindTo: $contentSize)
                    .background(Color.green.opacity(0.2))
            }
            .overlay(contentDragGesture(proxy: proxy))
        }
        .coordinateSpace(name: "ScrollView")
        .onPreferenceChange(OffsetPreferenceKey.self) { point in
            print("contentOffset", point)
            contentOffset = point
        }
    }

    private func contentDragGesture(proxy: GeometryProxy) -> ClearDragGestureView {
        ClearDragGestureView(onChanged: { value in
            UIApplication.shared.keyWindow?.endEditing(true)

//                    print("onChanged", value)
//                    print("value.translation.height", value.translation.height)
            let translationChange = value.translation.height
            if scrollViewStartDraggingOffset.y >= .zero, translationChange > 0 {
                if !scrollViewIsDragging {
                    scrollViewIsDragging = true
                }
                print("value.translation.height", translationChange)
                withAnimation(.interactiveSpring()) {
                    visibleHeight = currentHeight(proxy: proxy) - translationChange
                }
            }
//            else {
//                scrollViewStartDraggingOffset = contentOffset
//            }

        }, onEnded: { value in
            if scrollViewStartDraggingOffset.y >= .zero {
                if visibleHeight < height(for: .top, proxy: proxy) * 0.5 {
                    state = .bottom
                }
                updateToState(proxy: proxy)
            }

            if scrollViewIsDragging {
//                withAnimation(nil) {
                scrollViewIsDragging = false
//                }
            }
            scrollViewStartDraggingOffset = contentOffset
        })
    }

    private func dragGesture(proxy: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
//                if !stateObject.isDragging {
//                    stateObject.isDragging = true
//                }

//                let dragValue = value.translation.height - previousDragTranslation.height
//                let locationChange = value.startLocation.y - value.location.y
//                print("locationChange", locationChange)
//                print("gesture.location ->>", value.location)
//                print("gesture.translation ->>", value.translation)
//                print("gesture.startLocation ->>", value.startLocation)
                UIApplication.shared.keyWindow?.endEditing(true)
                withAnimation(.interactiveSpring()) {
                    let newHeight = currentHeight(proxy: proxy) - value.translation.height
                    let maxHeight = proxy.size.height + proxy.safeAreaInsets.top
                    visibleHeight = newHeight // min(newHeight, maxHeight)
                }
//                if locationChange > 0 {
//                    stateObject.offset += dragValue / 3
//                } else {
//                    stateObject.offset += dragValue
//                }

//                stateObject.previousDragTranslation = value.translation
            }
            .onEnded { value in
//                stateObject.previousDragTranslation = .zero
//                stateObject.isDragging = false

                print("value.predictedEndLocation ->>", value.predictedEndLocation)
                print("value.location ->>", value.location)
                print("value.translation.height ->>", value.translation.height)

                updateSheetFor(predictedEndLocation: value.predictedEndLocation, proxy: proxy)
            }
    }

    func updateSheetFor(
        predictedEndLocation: CGPoint,
        proxy: GeometryProxy
    ) {
        let topAnchorLine = proxy.size.height / 2
        let bottomAnchorLine = proxy.size.height / 2

        switch predictedEndLocation.y {
        case ...topAnchorLine:
            state = .top
//                case topAnchorLine ... bottomAnchorLine:
//                    state = .middle
        case bottomAnchorLine...:
            state = .bottom
        default:
//            print("Ended location outside screen \(value.location.y)")
            state = .bottom
        }

        updateToState(proxy: proxy)
    }

    func height(for state: SheetState, proxy: GeometryProxy) -> CGFloat {
        print("proxy.safeAreaInsets ->>", proxy.safeAreaInsets)
        print("proxy.size ->>", proxy.size)
        print("proxy.size.frame ->>", proxy.frame(in: .global).size)

        switch state {
        case .bottom:
            return headerSize // proxy.safeAreaInsets.bottom
//        case .middle:
//            return proxy.size.height / 2 + proxy.safeAreaInsets.bottom
        case .top:
            return proxy.size.height + proxy.safeAreaInsets.bottom
        case .hidden:
            return 0
        }
    }

    func currentHeight(proxy: GeometryProxy) -> CGFloat {
        height(for: state, proxy: proxy)
    }

    func updateToState(proxy: GeometryProxy) {
        withAnimation(.easeOut) {
            visibleHeight = currentHeight(proxy: proxy)
        }
    }

    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("ScrollView")).origin
                )
        }
        .frame(height: 0)
    }
}

extension BottomSearchableSheet {
    enum SheetState: String, Hashable {
        case top
//        case middle
        case bottom
        case hidden
    }
}

public struct BottomSearchableSheet_Preview: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }

    public struct ContentView: View {
        let data: [String]
//        [REDACTED_USERNAME] private var focused: Bool
        @State private var text: String = ""
        @State private var percent: CGFloat = 0

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
                Color.blue.brightness(0.2)
                    .cornerRadius(14)
                    .scaleEffect(min(1, abs(1 - percent / 30)), anchor: .bottom)
                    .edgesIgnoringSafeArea(.all)

                BottomSearchableSheet(searchText: $text, percent: $percent) {
                    LazyVStack(spacing: .zero) {
                        ForEach(data.filter { text.isEmpty ? true : $0.contains(text.lowercased()) }, id: \.self) { index in
                            Text(index)
                                .font(.title3)
                                .foregroundColor(Color.black.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.all)

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

extension View {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardDidHideNotification)
                    .map { _ in false }
            )
//      .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
