//
//  vMainViewController.m
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import "vMainViewController.h"
#import "chat.h"
#import "cMessage.h"
#import "vConnectViewController.h"
#import "cConnectCredentials.h"

@import SDL_net;


@interface vMainViewController ()

@property IBOutlet NSTableView* tableView;
@property IBOutlet NSTextField* messageTextField;
@property IBOutlet NSButton* sendButton;
@property NSMutableArray<cMessage*>* array;

@end


@implementation vMainViewController
{
    BOOL _isConnected;
    dispatch_semaphore_t _lock;
    cConnectCredentials* _credentials;
    TCPsocket _tcpsock;
    UDPsocket _udpsock;
    SDLNet_SocketSet _socketset;
    UDPpacket **_packets;
    struct {
        int active;
        Uint8 name[256+1];
    } _people[CHAT_MAXPEOPLE];
}

//MARK: OVERRIDE

- (void)viewDidLoad {
    [super viewDidLoad];
    self.array = [NSMutableArray new];
    _credentials = [cConnectCredentials connectCredentials];
    _lock = dispatch_semaphore_create(1);
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    if ([representedObject isKindOfClass:NSString.class]) {
        _credentials = [cConnectCredentials connectCredentialsWithServer:representedObject nick:NULL];
    } else if ([representedObject isKindOfClass:cConnectCredentials.class]) {
        _credentials = (cConnectCredentials*)representedObject;
    } else {
        return;
    }
    [self.view.window setTitle:_credentials.nick];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self performSelectorInBackground:@selector(connect) withObject:NULL];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    [self disconnect];
}

//MARK: UI

-(void)addMessage:(NSString*)message withType:(MessageType)type {
    NSInteger index = self.array.count;
    cMessage* object = [cMessage message:message withType:type];
    [self.array addObject:object];
    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectNone];
    [self.tableView scrollRowToVisible:index];
}

- (void)echoMessage:(NSString*)text {
    if ([NSThread isMainThread]) {
        [self addMessage:text withType:MessageTypeSystem];
    } else {
        [self performSelectorOnMainThread:@selector(echoMessage:) withObject:text waitUntilDone:NO];
    }
}

- (void)otherMessage:(NSString*)text {
    if ([NSThread isMainThread]) {
        [self addMessage:text withType:MessageTypeOther];
    } else {
        [self performSelectorOnMainThread:@selector(otherMessage:) withObject:text waitUntilDone:NO];
    }
}

//MARK: FUNC

- (void)sendHello:(NSString *)userName {
    IPaddress *myip;
    char hello[1+1+256];
    int i, n;
    const char* name;

    /* No people are active at first */
    for ( i=0; i<CHAT_MAXPEOPLE; ++i ) {
        _people[i].active = 0;
    }
    if (_tcpsock != NULL) {
        
        /* Get our chat handle */
        name = userName.UTF8String;
        [self echoMessage:[NSString stringWithFormat:@"Using name '%@'", userName]];

        /* Construct the packet */
        hello[0] = CHAT_HELLO;
        myip = SDLNet_UDP_GetPeerAddress(_udpsock, -1);
        memcpy(&hello[CHAT_HELLO_PORT], &myip->port, 2);
        if ( strlen(name) > 255 ) {
            n = 255;
        } else {
            n = (int) strlen(name);
        }
        hello[CHAT_HELLO_NLEN] = n;
        strncpy(&hello[CHAT_HELLO_NAME], name, n);
        hello[CHAT_HELLO_NAME+n++] = 0;

        /* Send it to the server */
        SDLNet_TCP_Send(_tcpsock, hello, CHAT_HELLO_NAME+n);
    }
}

- (void)send:(NSString*)text {
    int i;
    const char* buffer = text.UTF8String;
    int len = (int) strlen(buffer);

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    /* Send the text to each of our active channels */
    for ( i=0; i < CHAT_MAXPEOPLE; ++i ) {
        if ( _people[i].active ) {
            if ( len > _packets[0]->maxlen ) {
                len = _packets[0]->maxlen;
            }
            
            memcpy(_packets[0]->data, buffer, len);
            _packets[0]->len = len;
            SDLNet_UDP_Send(_udpsock, i, _packets[0]);
        }
    }
    dispatch_semaphore_signal(_lock);
}

- (void)disconnect {
    _isConnected = FALSE;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    /* Close the network connections */
    if (_tcpsock != NULL) {
        SDLNet_TCP_Close(_tcpsock);
        _tcpsock = NULL;
    }
    if (_udpsock != NULL) {
        SDLNet_UDP_Close(_udpsock);
        _udpsock = NULL;
    }
    if (_socketset != NULL) {
        SDLNet_FreeSocketSet(_socketset);
        _socketset = NULL;
    }
    if (_packets != NULL) {
        SDLNet_FreePacketV(_packets);
        _packets = NULL;
    }
    dispatch_semaphore_signal(_lock);
}

- (void)connect {
    int i;
    IPaddress serverIP;
    
    _isConnected = TRUE;
    
    /* Allocate a vector of packets for client messages */
    _packets = SDLNet_AllocPacketV(4, CHAT_PACKETSIZE);
    if (_packets == NULL) {
        NSLog(@"Couldn't allocate packets: Out of memory");
        [self disconnect];
        return;
    }

    /* Connect to remote host and create UDP endpoint */
    const char* server = _credentials.server.UTF8String;
    [self echoMessage: [NSString stringWithFormat:@"Connecting to %s ...", server]];
    SDLNet_ResolveHost(&serverIP, server, CHAT_PORT);
    if (serverIP.host == INADDR_NONE) {
        [self echoMessage: @"Couldn't resolve hostname"];
        [self disconnect];
        return;
    }
    
    /* If we fail, it's okay, the GUI shows the problem */
    _tcpsock = SDLNet_TCP_Open(&serverIP);
    if (_tcpsock == NULL) {
        [self echoMessage: @"Connect failed"];
        [self disconnect];
        return;
    }
    
    [self echoMessage: @"Connected"];
    
    /* Try ports in the range {CHAT_PORT - CHAT_PORT+10} */
    for ( i=0; (_udpsock == NULL) && i<10; ++i ) {
        _udpsock = SDLNet_UDP_Open(CHAT_PORT+i);
    }
    if ( _udpsock == NULL ) {
        [self echoMessage: @"Couldn't create UDP endpoint"];
        [self disconnect];
        return;
    }

    /* Allocate the socket set for polling the network */
    _socketset = SDLNet_AllocSocketSet(2);
    if (_socketset == NULL) {
        NSLog(@"Couldn't create socket set: %s", SDLNet_GetError());
        [self disconnect];
        return;
    }
    SDLNet_TCP_AddSocket(_socketset, _tcpsock);
    SDLNet_UDP_AddSocket(_socketset, _udpsock);
    
    /* Run the server thread, handling network data */
    [self sendHello: _credentials.nick];
    [self performSelectorInBackground:@selector(HandleNet) withObject:NULL];
}

//MARK: ACTION

- (IBAction)sendMessage:(id)sender {
    NSString* message = self.messageTextField.stringValue;
    if (message.length == 0) {
        return;
    }
    self.messageTextField.objectValue = NULL;
//    [self addMessage:message withType:MessageTypeMe];
    [self performSelectorInBackground:@selector(send:) withObject:message];
}

//MARK: SERVER

- (int)HandleServerData:(Uint8*)data {
    int used = 0;

    switch (data[0]) {
        case CHAT_ADD: {
            Uint8 which;
            IPaddress newip;

            /* Figure out which channel we got */
            which = data[CHAT_ADD_SLOT];
            if ((which >= CHAT_MAXPEOPLE) || _people[which].active) {
                /* Invalid channel?? */
                break;
            }
            /* Get the client IP address */
            newip.host=SDLNet_Read32(&data[CHAT_ADD_HOST]);
            newip.port=SDLNet_Read16(&data[CHAT_ADD_PORT]);

            /* Copy name into channel */
            memcpy(_people[which].name, &data[CHAT_ADD_NAME], 256);
            _people[which].name[256] = 0;
            _people[which].active = 1;

            NSString* nick = [NSString stringWithUTF8String:(const char*)&_people[which].name];
            /* Let the user know what happened */
            [self echoMessage:[NSString stringWithFormat:@"* New client on %d from %d.%d.%d.%d:%d (%@)",
                               which,
                               (newip.host>>24)&0xFF, (newip.host>>16)&0xFF, (newip.host>>8)&0xFF, newip.host&0xFF,
                               newip.port,
                               nick ]];

            /* Put the address back in network form */
            newip.host = SDL_SwapBE32(newip.host);
            newip.port = SDL_SwapBE16(newip.port);

            /* Bind the address to the UDP socket */
            SDLNet_UDP_Bind(_udpsock, which, &newip);
        }
        used = CHAT_ADD_NAME+data[CHAT_ADD_NLEN];
        break;
        case CHAT_DEL: {
            Uint8 which;

            /* Figure out which channel we lost */
            which = data[CHAT_DEL_SLOT];
            if ( (which >= CHAT_MAXPEOPLE) ||
                        ! _people[which].active ) {
                /* Invalid channel?? */
                break;
            }
            _people[which].active = 0;

            NSString* nick = [NSString stringWithUTF8String:(const char*)&_people[which].name];
            /* Let the user know what happened */
            [self echoMessage: [NSString stringWithFormat:@"* Lost client on %d (%@)", which, nick]];

            /* Unbind the address on the UDP socket */
            SDLNet_UDP_Unbind(_udpsock, which);
        }
        used = CHAT_DEL_LEN;
        break;
        case CHAT_BYE: {
            [self echoMessage:@"* Chat server full"];
        }
        used = CHAT_BYE_LEN;
        break;
        default: {
            /* Unknown packet type?? */;
        }
        used = 0;
        break;
    }
    return(used);
}

- (void)HandleServer {
    Uint8 data[512];
    int pos, len;
    int used;

    /* Has the connection been lost with the server? */
    len = SDLNet_TCP_Recv(_tcpsock, (char *)data, 512);
    if ( len <= 0 ) {
        SDLNet_TCP_DelSocket(_socketset, _tcpsock);
        SDLNet_TCP_Close(_tcpsock);
        _tcpsock = NULL;
        [self echoMessage:@"Connection with server lost!"];
        return;
    }
    pos = 0;
    while ( len > 0 ) {
        used = [self HandleServerData:&data[pos]];
        pos += used;
        len -= used;
        if ( used == 0 ) {
            /* We might lose data here.. oh well,
             we got a corrupt packet from server
             */
            len = 0;
        }
    }
}

- (void)HandleClient {
    int n = SDLNet_UDP_RecvV(_udpsock, _packets);
    while ( n-- > 0 ) {
        if ( _packets[n]->channel >= 0 ) {
            NSString* message = [[NSString alloc] initWithBytes:_packets[n]->data length:_packets[n]->len encoding:NSUTF8StringEncoding];
            NSString* nick = [NSString stringWithUTF8String:(const char*)&_people[_packets[n]->channel].name];
            [self otherMessage:[NSString stringWithFormat:@"[%@] %@", nick, message]];
        }
    }
}

- (void)HandleNet {
    while (_isConnected) {
        dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
        SDLNet_CheckSockets(_socketset, 100);
        if ( SDLNet_SocketReady(_tcpsock) ) {
            [self HandleServer];
        }
        if ( SDLNet_SocketReady(_udpsock) ) {
            [self HandleClient];
        }
        dispatch_semaphore_signal(_lock);
    }
}

@end

//MARK: - NSTableViewDataSource

@implementation vMainViewController (NSTableViewDataSource)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.array.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.array[row];
}
 
@end
