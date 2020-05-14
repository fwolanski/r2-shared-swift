//
//  Presentation.swift
//  r2-shared-swift
//
//  Created by Mickaël on 24/02/2020.
//
//  Copyright 2020 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

import Foundation

/// The Presentation Hints extension defines a number of hints for User Agents about the way content
/// should be presented to the user.
///
/// https://readium.org/webpub-manifest/extensions/presentation.html
/// https://readium.org/webpub-manifest/schema/extensions/presentation/metadata.schema.json
///
/// These properties are nullable to avoid having default values when it doesn't make sense for a
/// given `Publication`. If a navigator needs a default value when not specified,
/// `Presentation.defaultX` and `Presentation.X.default` can be used.
public struct Presentation: Equatable {

    /// Specifies whether or not the parts of a linked resource that flow out of the viewport are
    /// clipped.
    public let clipped: Bool?
    
    /// continuous Indicates how the progression between resources from the [readingOrder] should be
    /// handled.
    public let continuous: Bool?
    
    /// Suggested method for constraining a resource inside the viewport.
    public let fit: Fit?
    
    /// Suggested orientation for the device when displaying the linked resource.
    public let orientation: Orientation?
    
    /// Indicates if the overflow of linked resources from the `readingOrder` or `resources` should
    /// be handled using dynamic pagination or scrolling.
    public let overflow: Overflow?
    
    /// Indicates the condition to be met for the linked resource to be rendered within a synthetic
    ///  spread.
    public let spread: Spread?
    
    /// Hint about the nature of the layout for the linked resources (EPUB extension).
    public let layout: EPUBLayout?

    public init(clipped: Bool? = nil, continuous: Bool? = nil, fit: Fit? = nil, orientation: Orientation? = nil, overflow: Overflow? = nil, spread: Spread? = nil, layout: EPUBLayout? = nil) {
        self.clipped = clipped
        self.continuous = continuous
        self.fit = fit
        self.orientation = orientation
        self.overflow = overflow
        self.spread = spread
        self.layout = layout
    }
    
    public init(json: Any?) throws {
        guard json != nil else {
            self.init()
            return
        }
        guard let json = json as? [String: Any] else {
            throw JSONError.parsing(Presentation.self)
        }
        
        self.init(
            clipped: json["clipped"] as? Bool,
            continuous: json["continuous"] as? Bool,
            fit: parseRaw(json["fit"]),
            orientation: parseRaw(json["orientation"]),
            overflow: parseRaw(json["overflow"]),
            spread: parseRaw(json["spread"]),
            layout: parseRaw(json["layout"])
        )
    }
    
    public var json: [String: Any] {
        return makeJSON([
            "clipped": encodeIfNotNil(clipped),
            "continuous": encodeIfNotNil(continuous),
            "fit": encodeRawIfNotNil(fit),
            "orientation": encodeRawIfNotNil(orientation),
            "overflow": encodeRawIfNotNil(overflow),
            "spread": encodeRawIfNotNil(spread),
            "layout": encodeRawIfNotNil(layout)
        ])
    }
    
    /// Determines the layout of the given resource in this publication.
    /// Default layout is reflowable.
    public func layout(of link: Link) -> EPUBLayout {
        return link.properties.layout
            ?? layout
            ?? .reflowable
    }
    
    /// Suggested method for constraining a resource inside the viewport.
    public enum Fit: String {
        /// The content is centered and scaled to fit both dimensions into the viewport.
        case contain
        /// The content is centered and scaled to fill the viewport.
        case cover
        /// The content is centered and scaled to fit the viewport width.
        case width
        /// The content is centered and scaled to fit the viewport height.
        case height
    }
    
    /// Suggested orientation for the device when displaying the linked resource.
    public enum Orientation: String {
        case landscape, portrait, auto
    }
    
    /// Indicates if the overflow of linked resources from the `readingOrder` or `resources` should
    /// be handled using dynamic pagination or scrolling.
    public enum Overflow: String {
        /// Content overflow should be handled using dynamic pagination.
        case paginated
        /// Content overflow should be handled using scrolling.
        case scrolled
        /// The User Agent can decide how overflow should be handled.
        case auto
        
        @available(*, unavailable, message: "Use `Presentation.continuous` instead")
        static let scrolledContinuous: Overflow = .scrolled
    }
    
    /// Indicates how the linked resource should be displayed in a reading environment that
    /// displays synthetic spreads.
    public enum Page: String {
        case left, right, center
    }
    
    /// Indicates the condition to be met for the linked resource to be rendered within a synthetic
    /// spread.
    public enum Spread: String {
        /// The resource should be displayed in a spread only if the device is in landscape mode.
        case landscape
        /// The resource should be displayed in a spread whatever the device orientation is.
        case both
        /// The resource should never be displayed in a spread.
        case none
        /// The resource is left to the User Agent.
        case auto
    }

}
