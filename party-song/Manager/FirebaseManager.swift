//
//  FirebaseManager.swift
//  party-song
//
//  Created by Elliot Cunningham on 10/11/2018.
//  Copyright © 2018 Elliot Cunningham. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseUI

class FirebaseManager: NSObject {
    
    public static let sharedManager = FirebaseManager.init()
    
    public var isConnected: Bool = false
    public var currentUserUid: String?
    
    public var user: User?
    
    public var friendsRef: DatabaseReference?
    public var currentPlaylistRef: DatabaseReference?
    public var oldPlaylistsRef: DatabaseReference?
    
    public var friends: FUIArray?
    public var currentPlaylist: FUIArray?
    public var oldPlaylists: FUIArray?
    
    
    private override init() {
        super.init()
    }
    
    // MARK: Firebase connect
    
    public func connect(with email:String, password:String, completion: @escaping(_ success: Bool) -> Void) -> Void {
        if email.isEmpty || password.isEmpty {
            completion(false)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("error connect firebase", error)
                completion(false)
            }
            
            switch result {
                
            case .none:
                completion(false)
                return
            case .some(let result):
                self.isConnected = true
                self.currentUserUid = result.user.uid
                completion(true)
                return
            }
        }
    }
    
    public func connect(completion: @escaping(_ success: Bool) -> Void) -> Void {
        let userDefault = UserDefaults.standard
        guard let  email = userDefault.string(forKey: "kEmailConnectApp") else {
            completion(false)
            return
        }
        
        if let emailUser = Auth.auth().currentUser?.email {
            if email == emailUser {
                self.isConnected = true
                completion(true)
                return
            }
            else {
                do {
                    try Auth.auth().signOut()
                }
                catch let error {
                    print("error disconnect firebase", error)
                }
                
            }
        }
        
        guard let password = userDefault.string(forKey: "kPasswordConnectApp") else {
            completion(false)
            return
        }
        
        if email.isEmpty || password.isEmpty {
            completion(false)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("error signin firebase", error)
                completion(false)
                return
            }
            
            switch result {
                
            case .none:
                completion(false)
                return
                
            case .some(let result):
                self.isConnected = true
                self.currentUserUid = result.user.uid
                completion(true)
                return
            }
        }
        
    }
    
    // MARK : Create Firebase User
    
    public func createUser(email: String, password: String, completion: @escaping(_ success: Bool) -> Void) -> Void {
        if email.isEmpty || password.isEmpty {
            completion(false)
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("error create user Firebase", error)
                completion(false)
                return
            }
            
            switch result {
                
            case .none:
                completion(false)
                return
            case .some(let result):
                self.isConnected = true
                self.currentUserUid = result.user.uid
                self.initDataBase(uid: result.user.uid)
                completion(true)
                return
            }
        }
    }
    
    // MARK init database
    
    private func initDataBase(uid: String) -> Void {
        let rootRef = Database.database().reference()
        let usersRef = rootRef.child("users")
        let currentUserRef = usersRef.child(uid)
        currentUserRef.updateChildValues([ "friendsKey": self.getUniqueKey(for: currentUserRef),
                                           "currentPlaylistKey": self.getUniqueKey(for: currentUserRef),
                                           "oldPlaylistsKey": self.getUniqueKey(for: currentUserRef)
            ])
    }
    
    private func getUniqueKey(for ref: DatabaseReference) -> String {
        return ref.childByAutoId().key ?? "."
    }
    
    
    // MARK: fetch Data
    
    public func fetchFriends() -> Void {
        guard let uid = self.currentUserUid else { return }
        let rootRef = Database.database().reference()
        let currentUserRef = rootRef.child("users").child(uid)
        
        currentUserRef.child("firendsKey").observe(.value) { (snap) in
            if snap.exists() {
                let userFriendsKey = snap.value as! String
                self.friendsRef = rootRef.child("friends").child(userFriendsKey)
                guard let query = self.friendsRef?.queryOrdered(byChild: "name") else { return }
                let array = FUIArray(query: query)
                array.observeQuery()
                self.friends = array
            }
        }
    }
    
    public func fetchCurrentPlaylist(with uid:String) -> Void {
        // si is master on prend ca playlist sinon on prend la playlist d'un autre
        let rootRef = Database.database().reference()
        let currentUserRef = rootRef.child("users").child(uid)
        
        currentUserRef.child("currentPlaylistKey").observe(.value) { (snap) in
            if snap.exists() {
                let userCurrentPlaylistKey = snap.value as! String
                self.currentPlaylistRef = rootRef.child("currentPlaylists").child(userCurrentPlaylistKey)
                guard let query = self.currentPlaylistRef?.queryOrdered(byChild: "point") else { return }
                let array = FUIArray(query: query)
                array.observeQuery()
                self.currentPlaylist = array
            }
        }
    }
    
    public func fetchOldPlaylist() -> Void {
        guard let uid = self.currentUserUid else { return }
        let rootRef = Database.database().reference()
        let currentUserRef = rootRef.child("users").child(uid)
        
        currentUserRef.child("oldPlaylistsKey").observe(.value) { (snap) in
            if snap.exists() {
                let userOldPlaylistKey = snap.value as! String
                self.friendsRef = rootRef.child("oldPlaylists").child(userOldPlaylistKey)
                guard let query = self.friendsRef?.queryOrderedByKey() else { return }
                let array = FUIArray(query: query)
                array.observeQuery()
                self.oldPlaylists = array
            }
        }
    }
    
}
