//
//  Bundle++.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/17/24.
//

import Foundation

extension Bundle {
    var appBuild: String { getInfo("CFBundleVersion") }
    var appVersion: String { getInfo("CFBundleShortVersionString") }
    var copyright: String { getInfo("NSHumanReadableCopyright") }

    fileprivate func getInfo(_ key: String) -> String { infoDictionary?[key] as! String }
}
