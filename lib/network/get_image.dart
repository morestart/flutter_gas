import 'package:dio/dio.dart';

class RequestImage {
	final String baseUrl = "https://cn.bing.com";
	final String url = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US";
	String allUrl;
	Future getImage() async {
		try {
			Response response = await Dio().get(url);
			allUrl = baseUrl+response.data["images"][0]["url"];
			return allUrl;
		} catch (e) {
			print(e);
		}
	}
}