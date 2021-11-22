//
//  cMessage.h
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    MessageTypeMe,
    MessageTypeOther,
    MessageTypeSystem,
} MessageType;


NS_ASSUME_NONNULL_BEGIN

@interface cMessage : NSObject

@property MessageType messageType;
@property NSString* message;

+ (instancetype)message:(NSString*)message withType:(MessageType)type;
- (instancetype)init:(NSString*)message withType:(MessageType)type;

@end

NS_ASSUME_NONNULL_END
