//
//  ViewController.swift
//  chatTest
//
//  Created by Anjiss on 2/15/16.
//  Copyright © 2016 Anjiss. All rights reserved.
//

import UIKit
import Foundation
import Darwin.C

var localIP: String!
var serverIP: String!
var has_network = false
var is_server = false
var users : [String] = [] // ip addresses of all nearby users
var server_ips : [String] = [] // ip addresses of all nearby chatrooms
var users_ips : [String] = [] // if is_server, all ips in current chatroom
var server_userNames : [String] = [] // if is_server, all usernames in current chatroom
var localName: String!

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    

    @IBOutlet weak var userNumLabel: UILabel!
    @IBOutlet weak var ip_label: UILabel!

    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func create_room(sender: AnyObject) {
        is_server = true
        
        let alertController = UIAlertController(title: "Login",
            message: "type in your name", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "user_name"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "Join", style: UIAlertActionStyle.Default,
            handler: {
                action in
                let login = alertController.textFields!.first! as UITextField
                print("username：\(login.text)", NSThread.isMainThread())
                localName = login.text
                server_userNames.append(localName)
                server_ips.append(localIP)
                print("test create_room",NSThread.isMainThread())
                dispatch_async(dispatch_get_main_queue()) {
                    [unowned self] in
                    self.performSegueWithIdentifier("open_room", sender: self)
                }

        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    @IBAction func join_room(sender: AnyObject) {
        if !has_network {
            self.noNetworkAlert()
        } else {
            server_ips = []
            let maskIP = localIP.componentsSeparatedByString(".")
            let operationQueue = NSOperationQueue()
            for i in Range(0..<255){
                operationQueue.addOperationWithBlock(){
                    let pingIP = maskIP[0]+"."+maskIP[1]+"."+maskIP[2]+"."+String(i)
                    //print(pingIP)
                    let client:TCPClient = TCPClient(addr: pingIP, port: 420)
                    var (success,_)=client.connect(timeout: 1)
                    if success && pingIP != localIP{
                        server_ips.append(pingIP)
                        print(pingIP)
                        client.send(str:"/search" )
                    }
                    //client.close()
                }
            }
            operationQueue.waitUntilAllOperationsAreFinished()
            if server_ips.count == 0 {
                let alertController = UIAlertController(title: "Alert",
                    message: "No user found", preferredStyle: UIAlertControllerStyle.Alert)
                let cancelAction = UIAlertAction(title: "cancel", style: UIAlertActionStyle.Cancel, handler: nil)
                let okAction = UIAlertAction(title: "invite friends", style: UIAlertActionStyle.Default,
                    handler: {
                        action in
                        print("invite friends....")
                })
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                print(server_ips)
                self.tableView.reloadData()
            }
        }

    }
    @IBAction func search_users(sender: AnyObject) {
        if !has_network {
            self.noNetworkAlert()
        } else {
            users = []
            let maskIP = localIP.componentsSeparatedByString(".")
            let operationQueue = NSOperationQueue()
            for i in Range(0..<255){
                operationQueue.addOperationWithBlock(){
                    let pingIP = maskIP[0]+"."+maskIP[1]+"."+maskIP[2]+"."+String(i)
                    //print(pingIP)
                    let client:TCPClient = TCPClient(addr: pingIP, port: 419)
                    var (success,_)=client.connect(timeout: 1)
                    if success && pingIP != localIP{
                        users.append(pingIP)
                        print(pingIP)
                    }
                    client.close()
                }
            }
            operationQueue.waitUntilAllOperationsAreFinished()
            if users.count == 0 {
                let alertController = UIAlertController(title: "Alert",
                    message: "No user found", preferredStyle: UIAlertControllerStyle.Alert)
                let cancelAction = UIAlertAction(title: "cancel", style: UIAlertActionStyle.Cancel, handler: nil)
                let okAction = UIAlertAction(title: "invite friends", style: UIAlertActionStyle.Default,
                    handler: {
                        action in
                        print("invite friends....")
                })
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                print(users)
                self.userNumLabel.text = "\(users.count) users found"
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let localIP_array = getIFAddresses()
        if localIP_array.count == 0{
            print("no network")
        } else {
            has_network = true
            localIP = localIP_array[localIP_array.count-1]
        }
        //print(localIP)
        ip_label.text = localIP
        if let server:TCPServer = TCPServer(addr: localIP, port: 419) {
            var (success,msg)=server.listen()
            print("successfully set up local server!")
        }
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return server_ips.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel!.text = server_ips[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
        let serverIP_temp = server_ips[indexPath.row]
        print("ready for connect server" + serverIP_temp)
        let client:TCPClient = TCPClient(addr: serverIP_temp, port: 420)
        var (success,_)=client.connect(timeout: 5)
        if success {
            client.send(str:"/join" )
            
            let alertController = UIAlertController(title: "Login",
                message: "type in your name", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addTextFieldWithConfigurationHandler {
                (textField: UITextField!) -> Void in
                textField.placeholder = "user_name"
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel,
                handler: {
                    action in
                    client.send(str:"/cancel")
            })
            let okAction = UIAlertAction(title: "Join", style: UIAlertActionStyle.Default,
                handler: {
                    action in
                    let login = alertController.textFields!.first! as UITextField
                    print("username：\(login.text)", NSThread.isMainThread())
                    localName = login.text
                    client.send(str:localName)
                    print("test join_room",NSThread.isMainThread())
                    var feedback = client.read(1024*10)
                    let str = NSString(bytes: feedback!, length: feedback!.count, encoding: NSUTF8StringEncoding) as? String
                    print(str)
                    if str == "/approved" {
                        serverIP = serverIP_temp
                        dispatch_async(dispatch_get_main_queue()) {
                            [unowned self] in
                            self.performSegueWithIdentifier("open_room", sender: self)
                        }
                    } else {
                        self.userNameConflictAlert()
                    }
                    
                    
            })
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        
    }
    
    func getUserName() ->String {
        let alertController = UIAlertController(title: "Login",
            message: "type in your name", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            textField.placeholder = "user_name"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "Join", style: UIAlertActionStyle.Default,
            handler: {
                action in
                let login = alertController.textFields!.first! as UITextField
                print("username：\(login.text)", NSThread.isMainThread())
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        return alertController.textFields!.first!.text!
    }
    
    func noNetworkAlert () {
        let alertController = UIAlertController(title: "Alert",
            message: "Please connect WIFI first", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "WIFI Setting", style: UIAlertActionStyle.Default,
            handler: {
                action in
                print("call system setting....")
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    func userNameConflictAlert () {
        let alertController = UIAlertController(title: "Alert",
            message: "Please change your username", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}


func getIFAddresses() -> [String] {
    var addresses = [String]()
    
    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
    if getifaddrs(&ifaddr) == 0 {
        
        // For each interface ...
        for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
            let flags = Int32(ptr.memory.ifa_flags)
            var addr = ptr.memory.ifa_addr.memory
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                    if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String.fromCString(hostname) {
                                addresses.append(address)
                            }
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
    }
    
    return addresses
}