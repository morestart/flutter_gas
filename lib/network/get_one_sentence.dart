import 'package:dio/dio.dart';

class GetSentence {
	String sentence;
	String author;
	final url = "http://v3.wufazhuce.com:8000/api/channel/one/0/青岛";
	Future getSentence() async {
		try {
			Response response = await Dio().get(url);
			sentence = response.data["data"]["content_list"][0]["forward"];
			author = response.data["data"]["content_list"][0]["words_info"];
			Map<String, dynamic> data = {"sentence": sentence, "author": author} ;
			return data;
		} catch (e) {
			print(e);
		}
	}
}