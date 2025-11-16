//
//  Font+Rounded.swift
//  HslWidget
//
//  Font extension providing SF Pro Rounded fonts with defined scales
//

import SwiftUI

extension Font {
    /// SF Pro Rounded font variants with defined scales

    /// Large title - 36pt
    static let roundedLargeTitle = Font.system(size: 36, weight: .regular, design: .rounded)

    /// Title - 30pt
    static let roundedTitle = Font.system(size: 30, weight: .regular, design: .rounded)

    /// Title 2 - 24pt
    static let roundedTitle2 = Font.system(size: 24, weight: .regular, design: .rounded)

    /// Title 3 - 22pt
    static let roundedTitle3 = Font.system(size: 22, weight: .regular, design: .rounded)

    /// Headline - 19pt semibold
    static let roundedHeadline = Font.system(size: 19, weight: .semibold, design: .rounded)

    /// Body - 19pt regular
    static let roundedBody = Font.system(size: 19, weight: .regular, design: .rounded)

    /// Callout - 18pt regular
    static let roundedCallout = Font.system(size: 18, weight: .regular, design: .rounded)

    /// Subheadline - 17pt regular
    static let roundedSubheadline = Font.system(size: 17, weight: .regular, design: .rounded)

    /// Footnote - 15pt regular
    static let roundedFootnote = Font.system(size: 15, weight: .regular, design: .rounded)

    /// Caption - 14pt regular
    static let roundedCaption = Font.system(size: 14, weight: .regular, design: .rounded)

    /// Caption 2 - 13pt regular
    static let roundedCaption2 = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Custom size with optional weight
    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }
}
