//
//  CanvasObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

@objc(CanvasObject)
final class CanvasObject: NSManagedObject {
    @NSManaged var width: CGFloat
    @NSManaged var height: CGFloat
    @NSManaged var memo: MemoObject?
    @NSManaged var graphicContext: GraphicContextObject

    var size: CGSize {
        CGSize(width: width, height: height)
    }
}
