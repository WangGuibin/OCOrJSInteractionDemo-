*首先OC里要和JS去交互,先行引入头文件`#import <JavaScriptCore/JavaScriptCore.h>
`*
同样的,创建一个和屏幕大小的webView用于渲染HTML的页面, 
```swift
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:@"index"
                                                          ofType:@"html"];
    NSString * htmlCont = [NSString stringWithContentsOfFile:htmlPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    self.webView.delegate = self;
    [self.webView loadHTMLString: htmlCont baseURL:baseURL];
```
接下来写了一段蹩脚的HTML代码如下:
`index.html`
 ```html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
            <title>OC与JS交互</title>
            
            <script type="text/javascript">
                function secondClick(index) {
                    wgb_iOSHookJSButtonClick(index);
                }
            
            function showAlert(message) {
                alert('WGB__OC注入JS改变网页内容' + message);
            }
            
            function wgb_testCallOCKeyboard() {
                jsCallOCAlertKeyboard();
            }
            
            function wgb_endEidting() {
                wgb_keyboardResignFirstResponder();
            }
            
            var getIOSImage = function () { ///方法一
                var parameter = {'title': 'JS调OC', 'describe': '这里就是JS传给OC的参数'};
                // 在下面这里实现js 调用系统原生api
                window.iosDelegate.getImage(JSON.stringify(parameter));// 实现数据的 json 格式字符串
            }
            
            function getImageFromOC() { ///方法二
                iOSImageUpLoad();
            }
            
            // 这里是 iOS调用js的方法
            function setJSImageWithPath(arguments) {
                /// 用代理的赋值操作
                //var element = document.getElementById('changePhoto');
                //element.src =arguments['urlStringPath'];
                //var iOSParameters =  document.getElementById('iOSParameters');
                // iOSParameters.innerHTML = arguments['iosContent'] + arguments['img'];
                
                ///方法二的赋值操作
                var element_wgb = document.getElementById('wgb_changePhoto');
                element_wgb.src = arguments['urlStringPath'];
                var parameter_wgb = document.getElementById('wgb_iOSParameters');
                parameter_wgb.innerHTML = arguments['iosContent'] + arguments['img'];
            }
            
                </script>
            
            <style type="text/css">
                .alert {
                    color: green;
                    font-size: 30px;
                    border: blue 1px solid;
                }
            
            .args {
                color: red;
                font-size: 25px;
                border: solid 1px red;
            }
            
            .keyboard {
                color: blueviolet;
                font-size: 30px;
                border: solid 1px orange;
                
            }
            
            
                </style>
            
            
    </head>
    
    <body>
        <button class="alert" type="button" onclick="showAlert()"> JS测试弹窗showAlert</button>
        <br><br>
        <button class="args" onclick="secondClick(1)"> 我是参数1</button>
        <br><br>
        <button class="args" onclick="secondClick(2)"> 我是参数2</button>
        <br><br>
        <button class="args" onclick="secondClick(3)"> 我是参数3</button>
        <br><br>
        <button class="keyboard" onclick="wgb_testCallOCKeyboard()"> 召唤原生键盘</button>
        <br><br>
        <button class="keyboard" onclick="wgb_keyboardResignFirstResponder()"> 退回原生键盘</button>
        <br>
        <br>
        
        <!--        <div>-->
        <!--            <input type = "button" style="width: 50%;height: 5%;" id="Button" value="打开相机获取图片" onclick="getIOSImage()"></button>-->
        <!--        </div>-->

<br>
<br>

<!--        <div>-->
        <!--            ![](testImage.png)<!--src="图片的相对路径" 如果把html文件导入工程中，图片路径和OC一样只写图片名字和后缀就可以，（记得要先把图片添加到工程） 图片也可以实现按钮的方法getIOSImage -->
        <!--        </div>-->
        <!--        <span id="iOSParameters" style="width: 200px; height: 50%; color:orangered; font-size:15px" value="等待获取ios参数" >-->
        <br>
        
        <button class="args" type="button"
            " onclick="getImageFromOC()"> 打开相册相机方式二 </button>
            <br>            <br>
            <br>
            <br>

            ![](test.jpg)
            <br>
            
            <span id="wgb_iOSParameters" style="width: 200px; height: 50%; color: red;font-size: 15px" value="等待获取ios参数">
            
            <div style="background: red;width: 200px;height: 200px">
            小方块
            </div>
            
            </body>
            </html>

```
######将以上代码放到浏览器中渲染,只能看到几个按钮,一个破图片,点击的话也只有第一个弹框有反应,其他的都反应,因为内在逻辑实现的是按钮点击是有OC代码来反馈以及调用,比如弹起键盘,弹起原生的弹窗,收起键盘...打开系统相机相册等操作.


###1. OC里调用JS的函数
*一般这种情况是直接监听JS定义的函数*
```swift
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

//JS里的代码是这样的:
function secondClick(index) {
                    wgb_iOSHookJSButtonClick(index);
                }
///三个`button` `onclick`调用 `secondClick(1)` ,`secondClick(2)` `secondClick(3)`这样子,然后JS走index,  OC 调用`wgb_iOSHookJSButtonClick `,获取到参数值就是JS传过去的index,每次点击只传一个值.

```

###2. JS里调用OC的函数
*比如说JS调用原生的键盘啊,相机相册啥的...*
```swift
#pragma mark- 弹起键盘
- (void)alertKeyboard{
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"jsCallOCAlertKeyboard"] = ^(){ 
///这个方法名和前端的同学约定好就ok的
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
######以上这几个函数在网页加载完毕的时候就可以直接调用的 
```swift
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
```


[简书地址](http://www.jianshu.com/p/4ba2b26187b0)
