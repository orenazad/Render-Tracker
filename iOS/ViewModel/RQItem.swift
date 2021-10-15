//
//  RQItem.swift
//  Render Tracker
//
//  Created by Oren Azad on 6/2/21.
//

import Foundation


struct RQItem: Identifiable {
    var id = UUID().uuidString
    var compName: String
    var renderStatus: String
}

