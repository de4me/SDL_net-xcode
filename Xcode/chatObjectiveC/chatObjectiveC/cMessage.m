//
//  cMessage.m
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import "cMessage.h"


@implementation cMessage

+ (instancetype)message:(NSString*)message withType:(MessageType)type {
    return [[cMessage alloc] init:message withType:type];
}

- (instancetype)init:(NSString*)message withType:(MessageType)type {
    self = [self init];
    if (self != NULL) {
        self.messageType = type;
        self.message = message;
    }
    return self;
}

@end
