sub Main(args as object)
    print "=== STREMIO BRIDGE STARTING ==="
    print "Launch args: "; args
    
    ' Initialize the app
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create the main scene
    scene = screen.CreateScene("MainScene")
    screen.show()
    
    ' Always start the bridge listener for testing
    print "Starting bridge listener automatically for testing..."
    scene.callFunc("StartBridgeListener")
    
    ' Handle launch parameters (from Android app or test script)
    if args.DoesExist("contentId")
        print "Received contentId: "; args.contentId
        if args.contentId = "bridge_ready"
            print "Bridge ready signal received"
        else if args.contentId = "test_video"
            ' Handle test video from PowerShell script
            print "=== TEST VIDEO LAUNCH DETECTED ==="
            print "URL: "; args.url
            print "Title: "; args.title 
            print "Format: "; args.format
            
            if args.DoesExist("url") and args.DoesExist("title") and args.DoesExist("format")
                testStreamData = {
                    url: args.url,
                    title: args.title,
                    format: args.format,
                    quality: "highest"
                }
                print "Calling HandleECPStream with test data..."
                ' Wait a moment for scene to fully initialize
                sleep(1000)
                scene.callFunc("HandleECPStream", testStreamData)
                print "HandleECPStream called"
            else
                print "ERROR: Missing required test video parameters"
                print "Has URL: "; args.DoesExist("url")
                print "Has Title: "; args.DoesExist("title")
                print "Has Format: "; args.DoesExist("format")
            end if
        end if
    else
        print "No contentId provided in launch args"
    end if
    
    ' Main event loop
    while true
        msg = wait(0, m.port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                exit while
            end if
        end if
    end while
end sub
