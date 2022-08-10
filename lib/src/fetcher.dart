import 'dart:convert';

import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:fast_gbk/fast_gbk.dart';
import 'package:html/parser.dart';

class LinkInfo {
  final String? title;
  final String? descrition;
  final String? image;
  final String? icon;
  final String url;

  LinkInfo(
    this.url, {
    this.title,
    this.descrition,
    this.image,
    this.icon,
  });
}

const defaultUserAgent =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";

Future<LinkInfo?> fetchLinkInfo(String url, {String? userAgent}) async {
  if (!url.toLowerCase().startsWith('http')) {
    url = 'https://$url';
  }

  final uri = Uri.parse(url);
  final response = await http.get(uri, headers: {
    'User-Agent': userAgent ?? defaultUserAgent,
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    // 'Accept-Encoding': 'gzip, deflate, br',
    // 'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    // 'Host': uri.host,
    // 'Referer': url
  });

  // print(response.request?.headers);

  print(response.statusCode);

  if (response.statusCode == 200) {
    String? html;
    Document? document;
    try {
      html = utf8.decode(response.bodyBytes);
    } catch (e) {
      try {
        html = gbk.decode(response.bodyBytes);
      } catch (e) {
        print('gbk can not decode html');
      }
    }

    try {
      if (html == null) {
        document = parse(response.bodyBytes);
      } else {
        document = parse(html);
      }
    } catch (e) {
      print(e);
      return null;
    }

    String? title = _getMetaContent(document, 'og:title') ??
        _getMetaContent(document, 'twitter:title') ??
        _getMetaContent(document, 'og:site_name');
    if (title == null || title.isEmpty) {
      final titleElements = document.getElementsByTagName('title');
      if (titleElements.isNotEmpty) {
        title = titleElements.first.text;
      }
    }

    //descritpion
    String? description = _getMetaContent(document, 'og:description') ??
        _getMetaContent(document, 'description') ??
        _getMetaContent(document, 'twitter:description');
    if (description == null || description.isEmpty) {
      var meta = document.getElementsByTagName("meta");
      var metaDescriptions =
          meta.where((e) => e.attributes["name"] == "description");

      if (metaDescriptions.isNotEmpty) {
        description = metaDescriptions.first.attributes["content"];
      }

      if (description == null || description != "") {
        description = document.head?.getElementsByTagName("title").first.text;
      }
    }

    // image
    String? image = _getImageUrls(document, url);

    return LinkInfo(url, title: title, descrition: description, image: image);
  }

  return null;
}

String? _getImageUrls(Document document, String baseUrl) {
  final meta = document.getElementsByTagName('meta');
  var attribute = 'content';
  var elements = meta
      .where(
        (e) =>
            e.attributes['property'] == 'og:image' ||
            e.attributes['property'] == 'twitter:image',
      )
      .toList();

  if (elements.isEmpty) {
    elements = document.getElementsByTagName('img');
    attribute = 'src';
  }

  String? imageSrc = elements.first.attributes[attribute]?.trim();

  if (imageSrc != null) {
    if (imageSrc.contains('.svg') || imageSrc.contains('.gif')) return null;

    if (imageSrc.startsWith('data')) return null;

    if (imageSrc.startsWith('//')) imageSrc = 'http:$imageSrc';

    if (!imageSrc.startsWith("http")) {
      if (imageSrc.startsWith("/")) {
        imageSrc = "http://${_extractHost(baseUrl)}$imageSrc";
      } else {
        imageSrc = "http://${_extractHost(baseUrl)}/$imageSrc";
      }
    }
    return imageSrc;
  }

  // return elements.fold<List<String>>([], (previousValue, element) {
  //   String? imageSrc = element.attributes[attribute]?.trim();

  //   if (imageSrc != null && imageSrc.startsWith("http")) {
  //     imageSrc = "https://${_extractHost(baseUrl)}$imageSrc";
  //   }

  //   return imageSrc != null ? [...previousValue, imageSrc] : previousValue;
  // });
}

String _extractHost(String link) {
  Uri uri = Uri.parse(link);
  return uri.host;
}

String? _getMetaContent(Document document, String propertyValue) {
  final meta = document.getElementsByTagName('meta');
  final element = meta.firstWhere(
    (e) => e.attributes['property'] == propertyValue,
    orElse: () => meta.firstWhere(
      (e) => e.attributes['name'] == propertyValue,
      orElse: () => Element.tag(null),
    ),
  );

  return element.attributes['content']?.trim();
}
