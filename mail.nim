


## -d:ssl

import smtp, net
 
proc sendMail(fromAddr: string; toAddrs, ccAddrs: seq[string];
              subject, message, login, password, server: string) =
              
  var msg = createMessage(subject, message, toAddrs, ccAddrs, [("From","mjj@mabotech.com")])
  
  let smtpConn = newSmtp(useSsl = true, debug=true)
  
  smtpConn.connect(server, Port 465)
  
  smtpConn.auth(login, password)
  
  smtpConn.sendmail(fromAddr, toAddrs, $msg)

proc main():void = 

    sendMail(fromAddr = "mjj@mabotech.com",
             toAddrs  = @["mjj@mabotech.com"],
             ccAddrs  = @[],
             subject  = "Hi from Nim",
             message  = "Nim says hi!\nAnd see you again!8",
             login    = "mjj@mabotech.com",
             password = "XXXXXXXX",
             server = "smtp.exmail.qq.com"
             )
             
if isMainModule:
    main()