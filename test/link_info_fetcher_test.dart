import 'package:flutter_test/flutter_test.dart';

import 'package:link_info_fetcher/link_info_fetcher.dart';

void main() {
  test('adds one to input values', () async {
    final info = await fetchLinkInfo("https://www.2shu8.cc/txt/138908/");
    print(info?.title);
    print(info?.descrition);
    print(info?.image);
    expect(info?.title, "我侄子戒心实在太重了");
    expect(info?.descrition,
        "碧蓝的世界的热门小说我侄子戒心实在太重了最新精修章节,该小说文笔优秀、情节起伏波动精彩，爱书吧全文免费阅读，最新章节精修。");
    expect(info?.image,
        "http://bookcover.yuewen.com/qdbimg/349573/1017160731/180");
  });
}
