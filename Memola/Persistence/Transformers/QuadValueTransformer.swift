//
//  QuadValueTransformer.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/8/24.
//

import CoreData
import Foundation

@objc(QuadValueTransformer)
class QuadValueTransformer: ValueTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: QuadValueTransformer.self))

    override class func transformedValueClass() -> AnyClass {
        StrokeQuad.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let quads = value as? [StrokeQuad] else {
            assertionFailure("[Memola] - Failed to transform `[Quad]` to `Data`")
            return nil
        }
        do {
            let data = try JSONEncoder().encode(quads)
            return data
        } catch {
            print(error.localizedDescription)
            assertionFailure("[Memola] - Failed to transform `Quad` to `Data`")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            assertionFailure("[Memola] - Failed to transform `Data` to `Quad`")
            return nil
        }
        do {
            let quads = try JSONDecoder().decode([StrokeQuad].self, from: data)
            return quads
        } catch {
            print(error.localizedDescription)
            assertionFailure("[Memola] - Failed to transform `Data` to `Quad`")
            return nil
        }
    }

    static func register() {
        let transformer = QuadValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
