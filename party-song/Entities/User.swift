//
//  User.swift
//  party-song
//
//  Created by Elliot Cunningham on 10/11/2018.
//  Copyright © 2018 Elliot Cunningham. All rights reserved.
//

import UIKit
import Firebase

class User: NSObject {
    
    public let kFirstNameKey = "firstname"
    public let kLastNameKey = "lastname"
    public let kBirthdayKey = "birthday"
    public let kEmailKey = "email"
    public let kCurrentPartyKey = "currentParty"
    
    public var firstname: String?
    public var lastname: String?
    public var birthday: String?
    public var email: String?
    public var currentParty: String?
    public var isMaster: Bool = false
    public var ref: DatabaseReference?
    
    override init() {
        super.init()
    }
    
    init(snapshot:DataSnapshot) {
        super.init()
        
        if snapshot.exists() {
            self.ref = snapshot.ref
        }
        
        guard let dict = snapshot.value as? [String:Any] else { return }
        
        self.firstname = User.getString(for: kFirstNameKey, on: dict)
        self.lastname = User.getString(for: kLastNameKey, on: dict)
        self.birthday = User.getString(for: kBirthdayKey, on: dict)
        self.email = User.getString(for: kEmailKey, on: dict)
        self.currentParty = User.getString(for: kCurrentPartyKey, on: dict)
    }
    
    
    private class func getString(for key:String, on dict:[String:Any]) -> String? {
        guard let value = dict[key] as? String else {
            return nil
        }
        return value
    }
    
    
}
