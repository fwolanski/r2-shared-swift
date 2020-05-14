//
//  Locator.swift
//  r2-shared-swift
//
//  Created by Aferdita Muriqi on 2/13/19.
//
//  Copyright 2018 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//


import Foundation

/// https://github.com/readium/architecture/tree/master/locators
public struct Locator: Equatable, CustomStringConvertible, Loggable {

    /// The URI of the resource that the Locator Object points to.
    public var href: String  // URI
    
    /// The media type of the resource that the Locator Object points to.
    public var type: String
    
    /// The title of the chapter or section which is more relevant in the context of this locator.
    public var title: String?
    
    /// One or more alternative expressions of the location.
    public var locations: Locations
    
    /// Textual context of the locator.
    public var text: Text
    
    public init(href: String, type: String, title: String? = nil, locations: Locations = .init(), text: Text = .init()) {
        self.href = href
        self.type = type
        self.title = title
        self.locations = locations
        self.text = text
    }
    
    public init?(json: Any?) throws {
        if json == nil {
            return nil
        }
        guard let json = json as? [String: Any],
            let href = json["href"] as? String,
            let type = json["type"] as? String else
        {
            throw JSONError.parsing(Locator.self)
        }
        
        self.href = href
        self.type = type
        self.title = json["title"] as? String
        self.locations = try Locations(json: json["locations"])
        self.text = try Text(json: json["text"])
    }
    
    public init?(jsonString: String) throws {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
        } catch {
            Locator.log(.error, error)
            throw JSONError.parsing(Locator.self)
        }
        
        try self.init(json: json)
    }
    
    public init(link: Link) {
        let components = link.href.split(separator: "#", maxSplits: 1).map(String.init)
        var locations = Locations()
        if components.count > 1 {
            locations.fragments = [String(components[1])]
        }
        
        self.init(
            href: components.first ?? link.href,
            type: link.type ?? "",
            title: link.title,
            locations: locations
        )
    }
    
    public var json: [String: Any] {
        return makeJSON([
            "href": href,
            "type": type,
            "title": encodeIfNotNil(title),
            "locations": encodeIfNotEmpty(locations.json),
            "text": encodeIfNotEmpty(text.json)
        ])
    }
    
    public var jsonString: String? {
        return serializeJSONString(json)
    }
    
    public var description: String {
        return jsonString ?? "{}"
    }

    /// One or more alternative expressions of the location.
    /// https://github.com/readium/architecture/tree/master/models/locators#the-location-object
    public struct Locations: Equatable, Loggable {
        /// Contains one or more fragment in the resource referenced by the `Locator`.
        public var fragments: [String] = []
        /// Progression in the resource expressed as a percentage (between 0 and 1).
        public var progression: Double?
        /// Progression in the publication expressed as a percentage (between 0 and 1).
        public var totalProgression: Double?
        /// An index in the publication (>= 1).
        public var position: Int?

        /// Additional locations for extensions.
        public var otherLocations: [String: Any] {
            get { return otherLocationsJSON.json }
            set { otherLocationsJSON.json = newValue }
        }
        // Trick to keep the struct equatable despite [String: Any]
        private var otherLocationsJSON = JSONDictionary()
        
        public init(fragments: [String] = [], progression: Double? = nil, totalProgression: Double? = nil, position: Int? = nil, otherLocations: [String: Any] = [:]) {
            self.fragments = fragments
            self.progression = progression
            self.totalProgression = totalProgression
            self.position = position
            self.otherLocationsJSON = JSONDictionary(otherLocations) ?? JSONDictionary()
        }
        
        public init(json: Any?) throws {
            if json == nil {
                return
            }
            guard var json = JSONDictionary(json) else {
                throw JSONError.parsing(Locations.self)
            }
            var fragments = (json.pop("fragments") as? [String]) ?? []
            if let fragment = json.pop("fragment") as? String {
                fragments.append(fragment)
            }
            self.fragments = fragments
            self.progression = json.pop("progression") as? Double
            self.totalProgression = json.pop("totalProgression") as? Double
            self.position = json.pop("position") as? Int
            self.otherLocationsJSON = json
        }
        
        public init(jsonString: String) {
            do {
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
                try self.init(json: json)
            } catch {
                self.init()
                log(.error, error)
            }
        }

        public var isEmpty: Bool {
            return json.isEmpty
        }
        
        public var json: [String: Any] {
            return makeJSON([
                "fragments": encodeIfNotEmpty(fragments),
                "progression": encodeIfNotNil(progression),
                "totalProgression": encodeIfNotNil(totalProgression),
                "position": encodeIfNotNil(position)
            ], additional: otherLocations)
        }
        
        public var jsonString: String? {
            return serializeJSONString(json)
        }

        /// Syntactic sugar to access the `otherLocations` values by subscripting `Locations` directly.
        /// locations["cssSelector"] == locations.otherLocations["cssSelector"]
        public subscript(key: String) -> Any? {
            get { return otherLocations[key] }
            set { otherLocations[key] = newValue }
        }
        
        @available(*, deprecated, renamed: "init(jsonString:)")
        public init(fromString: String) {
            self.init(jsonString: fromString)
        }
        
        @available(*, deprecated, renamed: "jsonString")
        public func toString() -> String? {
            return jsonString
        }
        
        @available(*, deprecated, message: "Use `fragments.first` instead")
        public var fragment: String? {
            return fragments.first
        }
        
    }
    
    public struct Text: Equatable, Loggable {
        public var after: String?
        public var before: String?
        public var highlight: String?
        
        public init(after: String? = nil, before: String? = nil, highlight: String? = nil) {
            self.after = after
            self.before = before
            self.highlight = highlight
        }
        
        public init(json: Any?) throws {
            if json == nil {
                return
            }
            guard let json = json as? [String: Any] else {
                throw JSONError.parsing(Text.self)
            }
            self.after = json["after"] as? String
            self.before = json["before"] as? String
            self.highlight = json["highlight"] as? String
        }
        
        public init(jsonString: String) {
            do {
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
                try self.init(json: json)
            } catch {
                self.init()
                log(.error, error)
            }
        }
        
        public var json: [String: Any] {
            return makeJSON([
                "after": encodeIfNotNil(after),
                "before": encodeIfNotNil(before),
                "highlight": encodeIfNotNil(highlight)
            ])
        }
        
        public var jsonString: String? {
            return serializeJSONString(json)
        }
        
        @available(*, deprecated, renamed: "init(jsonString:)")
        public init(fromString: String) {
            self.init(jsonString: fromString)
        }
        
        @available(*, deprecated, renamed: "jsonString")
        public func toString() -> String? {
            return jsonString
        }
        
    }
    
}


@available(*, deprecated, message: "Use your own Bookmark model in your app, this one is not used by Readium 2 anymore")
public class Bookmark {
    public var id: Int64?
    public var bookID: Int = 0
    public var publicationID: String
    public var resourceIndex: Int
    public var locator: Locator
    public var creationDate: Date
    
    public init(id: Int64? = nil, publicationID: String, resourceIndex: Int, locator: Locator, creationDate: Date = Date()) {
        self.id = id
        self.publicationID = publicationID
        self.resourceIndex = resourceIndex
        self.locator = locator
        self.creationDate = creationDate
    }
    
    public convenience init(bookID: Int, publicationID: String, resourceIndex: Int, resourceHref: String, resourceType: String, resourceTitle: String, location: Locations, locatorText: LocatorText, creationDate: Date = Date(), id: Int64? = nil) {
        self.init(
            id: id,
            publicationID: publicationID,
            resourceIndex: resourceIndex,
            locator: Locator(
                href: resourceHref,
                type: resourceType,
                title: resourceTitle,
                locations: location,
                text: locatorText
            ),
            creationDate: creationDate
        )
    }

    public var resourceHref: String { return locator.href }
    public var resourceType: String { return locator.type }
    public var resourceTitle: String { return locator.title ?? "" }
    public var location: Locations { return locator.locations }
    public var locations: Locations? { return locator.locations }
    public var locatorText: LocatorText { return locator.text }
    
}
