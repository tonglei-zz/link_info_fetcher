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

Future<LinkInfo?> fetchLinkInfo(String url, {String? userAgent}) async {
  if (!url.toLowerCase().startsWith('http')) {
    url = 'https://$url';
  }

  final uri = Uri.parse(url);
  final response = await http
      .get(uri, headers: {if (userAgent != null) 'User-Agent': userAgent});

  String? html;

  if (response.statusCode == 200) {
    try {
      html = utf8.decode(response.bodyBytes);
    } catch (e) {
      try {
        html = gbk.decode(response.bodyBytes);
      } catch (e) {
        print('gbk can not decode html');
      }
    }

    print(html);

    if (html == null) {
      return null;
    }
  }

  final document = parse(html);
  // final openGraphMetaTags =
  //     document.head?.querySelectorAll("[property*='og:']");
  // var requiredAttributes = ['title', 'image'];
  // openGraphMetaTags?.forEach((element) {
  //   var ogTagTitle = element.attributes['property']?.split("og:")[1];
  //   var ogTagValue = element.attributes['content'];
  //   if ((ogTagValue != null && ogTagValue != "") ||
  //       requiredAttributes.contains(ogTagTitle)) {
  //     if (ogTagTitle == "image" && !ogTagValue!.startsWith("http")) {
  //       data[ogTagTitle] = "http://" + _extractHost(url) + ogTagValue;
  //     } else {
  //       data[ogTagTitle] = ogTagValue;
  //     }
  //   }
  // });

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
  if (imageSrc != null && !imageSrc.startsWith("http")) {
    imageSrc = "http://${_extractHost(baseUrl)}$imageSrc";
  }
  return imageSrc;

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
