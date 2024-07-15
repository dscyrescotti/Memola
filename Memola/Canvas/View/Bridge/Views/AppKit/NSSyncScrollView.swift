//
//  NSSyncScrollView.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/6/24.
//

#if canImport(AppKit)
import AppKit

protocol NSSyncScrollViewDelegate: AnyObject {
    func scrollViewDidZoom(_ scrollView: NSSyncScrollView)
    func scrollViewDidScroll(_ scrollView: NSSyncScrollView)
}

final class NSSyncScrollView: NSScrollView {
    weak var delegate: NSSyncScrollViewDelegate?

    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        delegate?.scrollViewDidZoom(self)
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        delegate?.scrollViewDidScroll(self)
    }
}
#endif
