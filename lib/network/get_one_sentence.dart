import 'package:dio/dio.dart';

class GetSentence {
	String sentence;
	String author;
	final url = "http://v3.wufazhuce.com:8000/api/channel/one/0/青岛";
	Future getSentence() async {
		try {
			Response response = await Dio().get(url);
			sentence = response.data["data"]["content_list"]["forward"];
			author = response.data["data"]["content_list"]["words_info"];
			return "{\"sentence\": $sentence, \"author\": $author}";
		} catch (e) {
			print(e);
		}
	}
}