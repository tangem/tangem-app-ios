////
////  TwinOnboardingBackground.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import SwiftUI
//
//struct TwinOnboardingBackground: View {
//	
//	struct ColoredLine: Identifiable {
//		let id = UUID()
//		let color: Color
//		let height: CGFloat
//		let offset: CGFloat
//	}
//	
//	enum ColorSet {
//		case gray, orange
//		
//		var lines: [ColoredLine] {
//			zip(zip(colors, heights), offset).map {
//				ColoredLine(color: $0.0.0, height: $0.0.1, offset: $0.1)
//			}
//		}
//		
//		var heights: [CGFloat] {
//			//[192, 81, 107, 72]
//            [1, 0.42, 0.557, 0.375]
//		}
//		
//		var offset: [CGFloat] {
//            [0, 0.45, 1.1, 1.75]
//		}
//		
//		var colors: [Color] {
//			switch self {
//			case .gray: return [Color.tangemGrayDark6.opacity(0.22),
//								Color.tangemGrayDark4.opacity(0.2),
//								Color.tangemGrayDark2.opacity(0.2),
//								Color.tangemGrayLight5.opacity(0.35)]
//			case .orange: return [Color.tangemWarning.opacity(0.55),
//								  Color.tangemWarning.opacity(0.45),
//								  Color.tangemWarning.opacity(0.35),
//								  Color.tangemWarning.opacity(0.25)]
//			}
//		}
//	}
//	
//	var colorSet: ColorSet = .orange
//	
//    [REDACTED_USERNAME]
//    func lines(baseHeight: CGFloat) -> some View {
//        ForEach(colorSet.lines) { line in
//            line.color
//                .frame(width: 600,
//                       height: baseHeight * line.height)
//                .rotationEffect(.degrees(-22))
//                .offset(y: -0.1 * baseHeight * line.offset)
//                .toAnyView() //Important!. fix iOS13 crash
//        }
//    }
//    
//    var body: some View {
//        GeometryReader { geo in
//            let baseHeight = geo.size.height * 0.25
//            ZStack(alignment: .top) {
//                VStack(spacing: 0.1 * baseHeight) {
//                    lines(baseHeight: baseHeight)
//                }
//            }.frame(width: geo.size.width,
//                    height: geo.size.height,
//                    alignment: .center)
//            .offset(y: -0.3 * geo.size.height)
//        }.clipped()
//        .edgesIgnoringSafeArea(.all)
//    }
//}
//
//struct TwinOnboardingBackground_Previews: PreviewProvider {
//    static var previews: some View {
//        TwinOnboardingBackground()
//            .previewGroup(devices: [.iPhone7, .iPhone8Plus, .iPhone12Pro, .iPhone12ProMax])
//    }
//}
