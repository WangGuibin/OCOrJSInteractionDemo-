//
//  ViewController.m
//  OCJS
//
//  Created by 王贵彬 on 2017/9/7.
//  Copyright © 2017年 王贵彬. All rights reserved.
//

#import "ViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "WGBSystemImagePickerManager.h"

@protocol JSDelegate <JSExport>

- (void)getImage:(id)parameter;

@end


@interface ViewController ()<UIWebViewDelegate,JSDelegate>

@property (assign,nonatomic) NSInteger indextNumb;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic,strong) WGBSystemImagePickerManager *manager;

@end

@implementation ViewController

- (WGBSystemImagePickerManager *)manager{
    if (!_manager) {
        _manager = [[WGBSystemImagePickerManager alloc] initWithViewController:self];
    }
    return _manager;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:@"index"
                                                          ofType:@"html"];
    NSString * htmlCont = [NSString stringWithContentsOfFile:htmlPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    self.webView.delegate = self;
    [self.webView loadHTMLString: htmlCont baseURL:baseURL];
    
    ///图片选择
    __weak typeof(self) weakSelf = self;
    [self.manager setDidSelectImageBlock:^(UIImage *img){
        weakSelf.indextNumb = weakSelf.indextNumb == 1?2:1;
        NSString *imgName = [NSString stringWithFormat:@"Varify%ld.jpg",weakSelf.indextNumb];
        [weakSelf saveImage: img  ImageName: imgName back:^(NSString *imagePath) {
                /**
                 *  这里是IOS 调 js 其中 setImageWithPath 就是js中的方法 setImageWithPath(),参数是字典
                 */
                JSContext *jsContext = [weakSelf.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
                JSValue *jsValue = jsContext[@"setJSImageWithPath"];//js设置图片方法
                [jsValue callWithArguments:@[@{@"urlStringPath": imagePath, @"iosContent":@"获取图片成功，把系统获取的图片路径传给js 让html显示",@"img" :  [NSString stringWithFormat:@"%@",img] }]]; ///传参数字典数组
        }];
    }];
}


// 加载完成开始监听js的方法
- (void)webViewDidFinishLoad:(UIWebView *)webView{
   JSContext *jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    jsContext[@"iosDelegate"] = self;
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception){
        context.exception = exception;
        NSLog(@"获取 self.jsContext 异常信息：%@",exception);
    };
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    [self js_ocCallBack];
    [self oc_jsCallBack];
    [self alertKeyboard];
    [self wgb_keyboardResignFirstResponder];
    [self js_callOCPhotoPickerImage]; 
    return YES;
}

#pragma mark- 戳按钮,OC监听获取JS传过来的参数 [JS调用OC]
- (void)js_ocCallBack{
    JSContext *js = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    js[@"wgb_iOSHookJSButtonClick"] = ^(){
        NSArray *args = [JSContext currentArguments];
        NSString *arg = [args.firstObject toString];
        NSLog(@"arg = %@",arg);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"JS调用OC,JS传过来的参数是" message: arg delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil];
            [alertView show];
        });
    };
}

#pragma mark- 执行JS脚本,改变网页内容或者交互 [OC 调用 JS]
- (void)oc_jsCallBack{
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    NSString *textJS = @"showAlert('这里是JS中alert弹出的message')";
    [context evaluateScript:textJS];
}

#pragma mark- 弹起键盘
- (void)alertKeyboard{
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"jsCallOCAlertKeyboard"] = ^(){
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextField *textfiled = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 10)];
        [self.view addSubview: textfiled];
        textfiled.hidden = YES;
        [textfiled becomeFirstResponder];
      });
    };
}

#pragma mark- 退出原生键盘
- (void)wgb_keyboardResignFirstResponder{
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"wgb_keyboardResignFirstResponder"] = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view endEditing:YES];
        });
    };
}

#pragma mark -<JSDelegate> ---  JS调用打开相册或照相机
- (void)getImage:(id)parameter{ ///代理的方式....
    // 把 parameter json字符串解析成字典
    NSString *jsonStr = [NSString stringWithFormat:@"%@", parameter];
    NSDictionary *jsParameDic = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding ] options:NSJSONReadingAllowFragments error:nil];
//    NSLog(@"js传来的json字典: %@", jsParameDic);
    for (NSString *key in jsParameDic.allKeys)
    {
        NSLog(@"jsParameDic[%@]:%@", key, jsParameDic[key]);
    }
    ///调用系统相机相册
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.manager quickAlertSheetPickerImage];
    });
}

#pragma mark- 指定一个方法去调用 相机/相册 选择图片
- (void)js_callOCPhotoPickerImage{
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"iOSImageUpLoad"] = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.manager quickAlertSheetPickerImage];
        });
    };
}


/**保存图片到沙盒并获取路径
 好像并不能直接传UIImage对象到前端,只能是先保存到本地一个路径这样传过去显示, 二进制不知道是怎么操作的,还有待学习
  */
- (BOOL)saveImage:(UIImage *)saveImage ImageName:(NSString *)imageName back:(void(^)(NSString *imagePath))back
{
    NSString *path = [self getImageDocumentFolderPath];
    NSData *imageData = UIImagePNGRepresentation(saveImage);
    NSString *documentsDirectory = [NSString stringWithFormat:@"%@/", path];
    // Now we get the full path to the file
    NSString *imageFile = [documentsDirectory stringByAppendingPathComponent:imageName];
    // and then we write it out
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //如果文件路径存在的话
    BOOL bRet = [fileManager fileExistsAtPath:imageFile];
    if (bRet)
    {
        //        NSLog(@"文件已存在");
        if ([fileManager removeItemAtPath:imageFile error:nil])
        {
            //            NSLog(@"删除文件成功");
            if ([imageData writeToFile:imageFile atomically:YES])
            {
                //                NSLog(@"保存文件成功");
                back(imageFile);
            }
        }
        else
        {
            
        }
        
    }
    else
    {
        if (![imageData writeToFile:imageFile atomically:NO])
        {
            [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            if ([imageData writeToFile:imageFile atomically:YES])
            {
                back(imageFile);
            }
        }
        else
        {
            return YES;
        }
        
    }
    return NO;
}

#pragma mark  从文档目录下获取Documents路径
- (NSString *)getImageDocumentFolderPath
{
    NSString *patchDocument = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@/Images", patchDocument];
}

@end
