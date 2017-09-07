# OCOrJSInteractionDemo-

```swift
 /**
 *  这里是IOS 调 js 其中 setImageWithPath 就是js中的方法 setImageWithPath(),参数是字典
 */
 JSContext *jsContext = [weakSelf.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
 JSValue *jsValue = jsContext[@"setJSImageWithPath"];//js设置图片方法
 [jsValue callWithArguments:@[@{@"urlStringPath": imagePath, @"iosContent":@"获取图片成功，把系统获取的图片路径传给js 让html显示",@"img" :  [NSString stringWithFormat:@"%@",img] }]]; ///传参数字典数组

```



```objc
// 加载完成开始监听js的方法
- (void)webViewDidFinishLoad:(UIWebView *)webView{
   JSContext *jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    jsContext[@"iosDelegate"] = self;
    jsContext.exceptionHandler = ^(JSContext *context, JSValue *exception){
        context.exception = exception;
        NSLog(@"获取 self.jsContext 异常信息：%@",exception);
    };
}
```


```objc
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

```



