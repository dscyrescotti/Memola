//
//  Date++.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/27/24.
//

import Foundation

extension Date {
    func getTimeDifference(to date: Date) -> String {
        let calendar = Calendar.current

        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: self, to: date)

        if let years = components.year, years > 0 {
            return "\(years) year\(years > 1 ? "s" : "") ago"
        } else if let months = components.month, months > 0 {
            return "\(months) month\(months > 1 ? "s" : "") ago"
        } else if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks) week\(weeks > 1 ? "s" : "") ago"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes > 1 ? "s" : "") ago"
        } else {
            return "just now"
        }
    }
}
