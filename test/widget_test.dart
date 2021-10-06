shouldOverrideUrlLoading:
(controller, NavigationAction navigationAction) async {
var uri = navigationAction.request.url!;
if (uri.scheme == 'intent') {
try {
var result = await platform
    .invokeMethod('launchKakaoTalk', {'url': uri.toString()});
if (result != null) {
await webViewController?.loadUrl(
urlRequest: URLRequest(url: Uri.parse(result)));
}

} catch (e) {
print('url fail $e');
}
return NavigationActionPolicy.CANCEL;
}
return NavigationActionPolicy.ALLOW;
},