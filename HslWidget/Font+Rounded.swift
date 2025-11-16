//
//  Font+Rounded.swift
//  HslWidget
//
//  Font extension providing SF Pro Rounded fonts with defined scales
//

import SwiftUI

extension Font {
    /// SF Pro Rounded font variants with defined scales

    /// Large title - 34pt
    static let roundedLargeTitle = Font.system(size: 34, weight: .regular, design: .rounded)

    /// Title - 28pt
    static let roundedTitle = Font.system(size: 28, weight: .regular, design: .rounded)

    /// Title 2 - 22pt
    static let roundedTitle2 = Font.system(size: 22, weight: .regular, design: .rounded)

    /// Title 3 - 20pt
    static let roundedTitle3 = Font.system(size: 20, weight: .regular, design: .rounded)

    /// Headline - 17pt semibold
    static let roundedHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Body - 17pt regular
    static let roundedBody = Font.system(size: 17, weight: .regular, design: .rounded)

    /// Callout - 16pt regular
    static let roundedCallout = Font.system(size: 16, weight: .regular, design: .rounded)

    /// Subheadline - 15pt regular
    static let roundedSubheadline = Font.system(size: 15, weight: .regular, design: .rounded)

    /// Footnote - 13pt regular
    static let roundedFootnote = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Caption - 12pt regular
    static let roundedCaption = Font.system(size: 12, weight: .regular, design: .rounded)

    /// Caption 2 - 11pt regular
    static let roundedCaption2 = Font.system(size: 11, weight: .regular, design: .rounded)

    /// Custom size with optional weight
    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }
}
