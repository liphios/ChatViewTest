//
//  LoginViewController.m
//  ChatViewTest
//
//  Created by caishangcai on 2017/11/27.
//  Copyright © 2017年 caishangcai. All rights reserved.
//

#import "LoginViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import <RongIMLib/RongIMLib.h>
#import <CommonCrypto/CommonDigest.h>
#import "RCDLiveKitCommonDefine.h"
#import "RCDLive.h"
@interface LoginViewController ()
@property (nonatomic,strong)UITextView *idTextField;
@property (nonatomic,strong)UITextView *nameTextField;
@property (nonatomic,strong)UITextView *chatRoomTextField;
@property (nonatomic,strong)UITextView *channelTextField;
@property (nonatomic,strong)UISwitch *modeSwitch;
@property (nonatomic,strong)UIButton *loginForLiveButton;
@property (nonatomic,strong)UIButton *loginForTVButton;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)clickLoginBtn:(id)sender {
    
//    ViewController *vc = [[ViewController alloc] init];
//    vc.conversationType = ConversationType_CHATROOM;
//    vc.view.backgroundColor = [UIColor whiteColor];
//    vc.targetId = @"ChatRoom01";
//    vc.contentURL = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
//    vc.isScreenVertical = YES;
//
//    [self.navigationController pushViewController:vc animated:YES];
//
    
    
    
    [self loginRongCloud:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];

}


/**
 *登录融云，这里只是为了演示所以直接调融云的server接口获取token来登录，为了您的app安全，这里建议您通过你们自己的服务端来获取token。
 *
 */
-(void)loginRongCloud:(NSString *)videoUrl
{
    NSString *userId = self.idTextField.text;
    NSString *userName = self.nameTextField.text;
    NSString *userProtrait = @"";
    
    userId = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication  sharedApplication] delegate];
    int x = arc4random() % 6;
    RCUserInfo *user =(RCUserInfo*)app.userList[x];
    userName = user.name;
    userProtrait = user.portraitUri;
    NSDictionary *params = @{@"userId":userId, @"name":userName, @"protraitUrl":userProtrait};
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"登录中...";
    
    NSString *url = @"http://api.cn.ronghub.com/user/getToken.json";
    //获得请求管理者
    AFHTTPRequestOperationManager* mgr = [AFHTTPRequestOperationManager manager];
    
    NSString *nonce = [NSString stringWithFormat:@"%d", rand()];
    
    long timestamp = (long)[[NSDate date] timeIntervalSince1970];
    
    NSString *unionString = [NSString stringWithFormat:@"%@%@%ld", RONGCLOUD_IM_APPSECRET, nonce, timestamp];
    const char *cstr = [unionString cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:unionString.length];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    mgr.requestSerializer.HTTPShouldHandleCookies = YES;
    
    NSString *timestampStr = [NSString stringWithFormat:@"%ld", timestamp];
    [mgr.requestSerializer setValue:RONGCLOUD_IM_APPKEY forHTTPHeaderField:@"App-Key"];
    [mgr.requestSerializer setValue:nonce forHTTPHeaderField:@"Nonce"];
    [mgr.requestSerializer setValue:timestampStr forHTTPHeaderField:@"Timestamp"];
    [mgr.requestSerializer setValue:output forHTTPHeaderField:@"Signature"];
    __weak __typeof(&*self)weakSelf = self;
    [mgr POST:url parameters:params
      success:^(AFHTTPRequestOperation* operation, NSDictionary* responseObj) {
          NSLog(@"success");
          NSNumber *code = responseObj[@"code"];
          if (code.intValue == 200) {
              NSString *token = responseObj[@"token"];
              NSString *userId = responseObj[@"userId"];
              
              [[RCDLive sharedRCDLive] connectRongCloudWithToken:token success:^(NSString *loginUserId) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      RCUserInfo *user = [[RCUserInfo alloc]init];
                      user.userId = userId;
                      user.portraitUri = userProtrait;
                      user.name = userName;
                      [RCIMClient sharedRCIMClient].currentUserInfo = user;
                      
                      ViewController *vc = [[ViewController alloc] init];
                      vc.conversationType = ConversationType_CHATROOM;
                      vc.targetId = @"ChatRoom01";
                      vc.contentURL = videoUrl;
                      vc.isScreenVertical = YES;
                      vc.view.backgroundColor = [UIColor grayColor];
                      [self.navigationController pushViewController:vc animated:YES];
                      
                      
                      
                      
                  });
              } error:^(RCConnectErrorCode status) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      _loginForTVButton.enabled = YES;
                      _loginForLiveButton.enabled = YES;
                  });
                  
              } tokenIncorrect:^{
                  dispatch_async(dispatch_get_main_queue(), ^{
                      _loginForTVButton.enabled = YES;
                      _loginForLiveButton.enabled = YES;
                  });
              }];
              
              dispatch_async(dispatch_get_main_queue(), ^{
                  [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                  _loginForTVButton.enabled = YES;
                  _loginForLiveButton.enabled = YES;
              });
              
          } else {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                  _loginForTVButton.enabled = YES;
                  _loginForLiveButton.enabled = YES;
              });
          }
          
      } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
          NSLog(@"error");
          dispatch_async(dispatch_get_main_queue(), ^{
              [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
              _loginForTVButton.enabled = YES;
              _loginForLiveButton.enabled = YES;
          });
      }];
    
}


@end
