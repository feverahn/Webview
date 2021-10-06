import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:kakao_flutter_sdk/all.dart';
import 'package:url_launcher/url_launcher.dart';


Future main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(new MyApp());
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}



class _MyAppState extends State<MyApp> {

  final GlobalKey webViewKey = GlobalKey();
  static const platform = const MethodChannel('intent');

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: SafeArea(
              child: Column(children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      InAppWebView(
                        key: webViewKey,
                        initialUrlRequest:
                        URLRequest(url: Uri.parse("https://crplaza.kr/")),
                        initialOptions: options,
                        pullToRefreshController: pullToRefreshController,
                        onWebViewCreated: (controller) {
                          webViewController = controller;
                          // 카카오톡 핸들러호출
                          // webViewController?.addJavaScriptHandler(
                          //     handlerName: 'Kakao',
                          //     callback: (arguments) async {
                          //       try {
                          //         final installed = await isKakaoTalkInstalled();
                          //         final authCode = installed
                          //             ? await AuthCodeClient.instance.requestWithTalk()
                          //             : await AuthCodeClient.instance.request();
                          //         return authCode;
                          //       } on KakaoAuthException catch (e) {
                          //         return null;
                          //       } on Exception catch (e) {
                          //         return null;
                          //       }
                          //     });
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        androidOnPermissionRequest: (controller, origin, resources) async {
                          return PermissionRequestResponse(
                              resources: resources,
                              action: PermissionRequestResponseAction.GRANT);
                        },
                        // 기존
                        shouldOverrideUrlLoading: (controller, navigationAction) async {
                          var uri = navigationAction.request.url!;

                          if (![ "http", "https", "file", "chrome",
                            "data", "javascript", "about"].contains(uri.scheme)) {
                            if (await canLaunch(url)) {
                              // Launch the App
                              await launch(
                                url,
                              );
                              // and cancel the request
                              return NavigationActionPolicy.CANCEL;
                            }
                          }

                          return NavigationActionPolicy.ALLOW;
                        },

                        // shouldOverrideUrlLoading:
                        //     (controller, NavigationAction navigationAction) async {
                        //   var uri = navigationAction.request.url!;
                        //   if (uri.scheme == 'intent') {
                        //     try {
                        //       var result = await platform
                        //           .invokeMethod('launchKakaoTalk', {'url': uri.toString()});
                        //       if (result != null) {
                        //         await webViewController?.loadUrl(
                        //             urlRequest: URLRequest(url: Uri.parse(result)));
                        //       }
                        //
                        //     } catch (e) {
                        //       print('url fail $e');
                        //     }
                        //     return NavigationActionPolicy.CANCEL;
                        //   }
                        //   return NavigationActionPolicy.ALLOW;
                        // },

                        onLoadStop: (controller, url) async {
                          pullToRefreshController.endRefreshing();
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onLoadError: (controller, url, code, message) {
                          pullToRefreshController.endRefreshing();
                        },
                        onProgressChanged: (controller, progress) {
                          if (progress == 100) {
                            pullToRefreshController.endRefreshing();
                          }
                          setState(() {
                            this.progress = progress / 100;
                            urlController.text = this.url;
                          });
                        },
                        onUpdateVisitedHistory: (controller, url, androidIsReload) {
                          setState(() {
                            this.url = url.toString();
                            urlController.text = this.url;
                          });
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          print(consoleMessage);
                        },
                      ),
                    ],
                  ),
                ),

              ]))),
    );
  }
}