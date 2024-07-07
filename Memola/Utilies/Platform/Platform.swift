//
//  Platform.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/6/24.
//

import SwiftUI

enum Platform {
    #if os(macOS)
    typealias View = NSView
    typealias Color = NSColor
    typealias Image = NSImage
    typealias ScrollView = NSSyncScrollView
    typealias Application = NSApplication
    typealias ViewController = NSViewController
    typealias TapGestureRecognizer = NSClickGestureRecognizer
    typealias ViewControllerRepresentable = NSViewControllerRepresentable
    #else
    typealias View = UIView
    typealias Color = UIColor
    typealias Image = UIImage
    typealias ScrollView = UIScrollView
    typealias Application = UIApplication
    typealias ViewController = UIViewController
    typealias TapGestureRecognizer = UITapGestureRecognizer
    typealias ViewControllerRepresentable = UIViewControllerRepresentable
    #endif
}
