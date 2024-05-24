//
//  StrokeGenerator.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

protocol StrokeGenerator {
    associatedtype Configuration

    var configuration: Configuration { get set }

    func begin(at point: CGPoint, on stroke: Stroke)
    func append(to point: CGPoint, on stroke: Stroke)
    func finish(at point: CGPoint, on stroke: Stroke)
}
