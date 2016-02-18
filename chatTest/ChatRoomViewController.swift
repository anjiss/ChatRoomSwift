//
//  ChatRoomViewController.swift
//  chatTest
//
//  Created by Anjiss on 2/16/16.
//  Copyright © 2016 Anjiss. All rights reserved.
//

import UIKit
import Foundation
import Darwin.C

class ChatRoomViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var testLabel: UILabel!
    //var timer = NSTimer()
    @IBAction func updateBut(sender: AnyObject) {
        if !is_server{
            self.listenJoin()
        }
    }
    @IBAction func leaveRoom(sender: AnyObject) {
        if is_server {
        
        } else {
            let client:TCPClient = TCPClient(addr: serverIP, port: 420)
            var (success,errmsg)=client.connect(timeout: 5)
            if success{
                client.send(str: "/userleave " + localName)
            }else{
                print(errmsg)
            }
            self.performSegueWithIdentifier("leave_room", sender: self)
            client.close()
        }
    }


    @IBOutlet weak var ChatText: UITextView!
    @IBAction func sendBut(sender: AnyObject) {
        chatLabel.text = chatMessage.text
        ChatText.text = ChatText.text! + localName + ": " + chatMessage.text! + "\n"
        if !is_server {
            let client:TCPClient = TCPClient(addr: serverIP, port: 420)
            var (success,errmsg)=client.connect(timeout: 5)
            if success{
                client.send(str: "/msg " + localName + ": " + chatMessage.text! + "\n")
            }else{
                print(errmsg)
            }
        } else {
            for ip in users_ips {
                print(ip)
                //let client = self.server.accept()
                //client!.send(str: "/msg " + localName + ": " + chatMessage.text! + "\n")
            }
        
        }
        chatMessage.text = ""
    }
    @IBOutlet weak var chatMessage: UITextField!

    @IBOutlet weak var chatLabel: UILabel!
    var server: TCPServer!
    var client: TCPClient!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chatMessage.delegate = self
        ChatText.text = ""
        ChatText.userInteractionEnabled = true
        ChatText.editable = false
        if is_server {
            testLabel.text = "1 users"
            let queueJoin = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            dispatch_async(queueJoin) {
                self.listenJoin()
            }
        } else {
            testLabel.text = "1 users"
            //timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "listenJoin", userInfo: nil, repeats: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func listenJoin () {
        if is_server{
            server = TCPServer(addr: localIP, port: 420)
            var (success,msg) = server.listen()
            if success{
                print("successfully join chatroom!")
                print("check 1")
                while true {
                    var s = update()
                    dispatch_async(dispatch_get_main_queue()){
                        if s != "" {
                            self.ChatText.text = self.ChatText.text + s
                        } else {
                            self.testLabel.text = "\(server_userNames.count) users"
                        }
                    }
                    
                }
                print("check 2")
            }
        } else {
            if true{
                print("successfully join chatroom!")
                print("check 1")
                var s = updateClient()
                if s != "" {
                    self.ChatText.text = s
                } else {
                    //
                }

                print("check 2")
            }
        }
        
    
    }
    func update() -> String {
        print("working...")
        var s = ""
        if var c = self.server.accept(){
            print("newclient from:\(c.addr)[\(c.port)]")
            if var d=c.read(1024*10) {
                let str = NSString(bytes: d, length: d.count, encoding: NSUTF8StringEncoding) as? String
                print(str)
                if str == "/join" {
                    if var d=c.read(1024*10) {
                        let str = NSString(bytes: d, length: d.count, encoding: NSUTF8StringEncoding) as? String
                        print(str)
                        if str != "/cancel" {
                            let userName = str!
                            if !server_userNames.contains(userName) {
                                server_userNames.append(userName)
                                users_ips.append(c.addr)
                                c.send(str: "/approved")
                                
                            } else {
                                c.send(str: "/denied")
                            }
                            
                        }
                    }
                } else if str!.rangeOfString("/msg ") != nil {
                    s = str!.stringByReplacingOccurrencesOfString("/msg ", withString: "")
                    print(s)
                } else if str!.rangeOfString("/userleave ") != nil {
                    let str_temp = str!.stringByReplacingOccurrencesOfString("/userleave ", withString: "")
                    server_userNames = server_userNames.filter {$0 != str_temp}
                    users_ips = users_ips.filter {$0 != c.addr}
                } else if str!.rangeOfString("/ready") != nil {
                    print(str)
                    c.send(str: "/update " + self.ChatText.text)
                }
            }
            c.close()
        }
        return s
    }
    func updateClient() -> String {
        print("working...")
        client = TCPClient(addr: serverIP, port: 420)
        client.connect(timeout: 5)
        client.send(str:"/ready" )
        var s = ""
        if var d=client.read(1024*10) {
            let str = NSString(bytes: d, length: d.count, encoding: NSUTF8StringEncoding) as? String
            print(str)
            if str == "/join" {
                if var d=client.read(1024*10) {
                    let str = NSString(bytes: d, length: d.count, encoding: NSUTF8StringEncoding) as? String
                    print(str)
                    if str != "/cancel" {
                        let userName = str!
                        if !server_userNames.contains(userName) {
                            server_userNames.append(userName)
                            users_ips.append(client.addr)
                            client.send(str: "/approved")
                        } else {
                            client.send(str: "/denied")
                        }
                    }
                }
            } else if str!.rangeOfString("/msg ") != nil {
                s = str!.stringByReplacingOccurrencesOfString("/msg ", withString: "")
                print(s)
            } else if str == "/confrim" {
                d=client.read(1024*10)!
                let str = NSString(bytes: d, length: d.count, encoding: NSUTF8StringEncoding) as? String
                print(str)
            } else if str!.rangeOfString("/update ") != nil {
                s = str!.stringByReplacingOccurrencesOfString("/update ", withString: "")
            }
        }
        client.close()
        return s
    }

    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        chatMessage.resignFirstResponder()
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
