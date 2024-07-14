//
//  NSCenterClipView.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/6/24.
//

#if canImport(AppKit)
import AppKit

final class NSCenterClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {
            if (rect.size.width > containerView.frame.size.width) {
                rect.origin.x = (containerView.frame.width - rect.width) / 2
            }
            if(rect.size.height > containerView.frame.size.height) {
                rect.origin.y = (containerView.frame.height - rect.height) / 2
            }
        }
        return rect
    }
}
#endif
