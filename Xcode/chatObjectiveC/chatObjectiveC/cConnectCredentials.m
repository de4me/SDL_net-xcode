//
//  cConnectCredentials.m
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import "cConnectCredentials.h"


@implementation cConnectCredentials

+ (instancetype)connectCredentials {
    return [self connectCredentialsWithServer:NULL nick:NULL];
}

+ (instancetype)connectCredentialsWithServer:(NSString* _Nullable)server nick:(NSString* _Nullable)nick {
    return [[self alloc] initWithServer:server nick:nick];
}

- (instancetype)initWithServer:(NSString* _Nullable)server nick:(NSString* _Nullable)nick {
    self = [super init];
    if (self != NULL) {
        self.nick = (nick != NULL) && (nick.length > 0) ? nick : NSUserName();
        self.server = (server != NULL) && (server.length > 0) ? server : @"localhost";
    }
    return self;
}

@end
