//
//  cConnectCredentials.h
//  chatObjectiveC
//
//  Created by DE4ME on 21.11.2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface cConnectCredentials : NSObject

@property NSString* nick;
@property NSString* server;

+ (instancetype)connectCredentials;
+ (instancetype)connectCredentialsWithServer:(NSString* _Nullable)server nick:(NSString* _Nullable)nick;
- (instancetype)initWithServer:(NSString* _Nullable)server nick:(NSString* _Nullable)nick;

@end

NS_ASSUME_NONNULL_END
