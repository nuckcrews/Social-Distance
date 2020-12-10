//
//  human.swift
//  Social Distance
//
//  Created by Nick Crews on 4/27/20.
//  Copyright © 2020 People. Love. Change. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

class human {
    
    private var _latitude: Double!
    private var _longitidue: Double!
    private var _key: String!
    private var _id: String!
    private var _fcm: String!
    private var _ref: DatabaseReference!

    var fcm: String! {
        return _fcm
    }
    var id: String! {
        return _id
    }
    var key: String! {
        return _key
    }
    var latitude: Double! {
        return _latitude
    }
    var longitude: Double! {
        return _longitidue
    }

    init(fcm: String, latitude: Double, longitude: Double, id: String) {
        _longitidue = longitude
        _latitude = latitude
        _fcm = fcm
        _id = id
    }
    init(key: String, postData: Dictionary<String, AnyObject>) {
        _key = key
        if let fcm = postData["fcm"] as? String {
            _fcm = fcm
        }
        if let id = postData["id"] as? String {
            _id = id
        }
        if let longitude = postData["longitude"] as? Double {
            _longitidue = longitude
        }
        if let latitude = postData["latitude"] as? Double {
            _latitude = latitude
        }
        _ref = Database.database().reference().child("actives").child(key)
    }
    
}
