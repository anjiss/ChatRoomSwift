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
    var timer = NSTimer()
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
                let client:TCPClient = TCPClient(addr: ip, port: 420)
                var (success,errmsg)=client.connect(timeout: 5)
                if success{
                    client.send(str: "/msg " + localName + ": " + chatMessage.text! + "\n")
                }else{
                    print(errmsg)
                }

            }
        
        }
        chatMessage.text = ""
    }
    @IBOutlet weak var chatMessage: UITextField!

    @IBOutlet weak var chatLabel: UILabel!
    var server: TCPServer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chatMessage.delegate = self
        ChatText.text = ""
        ChatText.userInteractionEnabled = true
        ChatText.editable = false
        if true {
            testLabel.text = "1 users"
            let queueJoin = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            dispatch_async(queueJoin) {
                self.listenJoin()
            }
            //let queueListen = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            //dispatch_async(queueListen) {
            //    self.listenMsg()
            //}
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func listenJoin () {
        server = TCPServer(addr: localIP, port: 420)
        var (success,msg)=server.listen()
        print("successfully join chatroom!")
        if success{
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
    
    }
    func update() -> String {
        print("working...")
        var s = ""
        if var c = self.server.accept(){
            print("newclient from:\(c.addr)[\(c.port)]")
            if var d=c.read(1024*10) {
                let str = NSString(bytes: d, length: d.count, encoding: NSUTF8StringEncoding) as? String
                //print(str)
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
                }
            }
        //self.testLabel.text = str
        //c!.send(data: d!)
            //c.close()
        }
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
