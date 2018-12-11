import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';

class Lang {
  final String ja;
  final String en;

  Lang(this.ja, this.en);

  factory Lang.fromCSV(List<String> stringList, int fromIndex, int toIndex) =>
      Lang(stringList[fromIndex], stringList[toIndex]);

  bool isEmpty() => this.ja.isEmpty || this.en.isEmpty;

  bool isNonEmpty() => !this.isEmpty();

  String toString() => "${this.ja} | ${this.en}";

  String convertRecord(String record) =>
      record.replaceAll("\"${this.ja}\"", "\"${this.en}\"");
}

String _caseString(dynamic value) {
  if (value is String) {
    return value;
  }

  return "";
}

class LangSink extends Sink<List> {
  Sink<Lang> innerSink;
  final int fromIndex;
  final int toIndex;

  LangSink(this.innerSink, this.fromIndex, this.toIndex);

  void add(List data) {
    var stringList = data.map(_caseString).toList();
    var lang = Lang.fromCSV(stringList, fromIndex, toIndex);
    innerSink.add(lang);
  }

  void close() => innerSink.close();
}

class StringListToLangConverter extends Converter<List, Lang> {
  final int fromIndex;
  final int toIndex;

  StringListToLangConverter(this.fromIndex, this.toIndex);

  @override
  Lang convert(List<dynamic> input) {
    var stringList = input.map(_caseString).toList();
    return Lang.fromCSV(stringList, fromIndex, toIndex);
  }

  @override
  Sink<List> startChunkedConversion(Sink<Lang> sink) {
    return new LangSink(sink, fromIndex, toIndex);
  }
}

mixin UseFileReader {
  File readFile(String path);
}

mixin MixInFileReader {
  File readFile(String path) => File(path);
}

mixin UseOutput {
  void dist(String content);
}

mixin MixInOutput {
  void dist(String content) => print(content);
}

mixin TranslateRecord implements UseFileReader, UseOutput {
  void execute(String recordFilePath, String csvFilePath, int fromIndex, int toIndex) {
    final recordFile = readFile(recordFilePath).readAsStringSync();
    final input = readFile(csvFilePath).openRead();

    input
        .transform(Utf8Decoder())
        .transform(CsvCodec(eol: "\n").decoder)
        .transform(StringListToLangConverter(fromIndex, toIndex))
        .where((lang) => lang.isNonEmpty())
        .fold(recordFile, (record, lang) => lang.convertRecord(record))
        .then(dist);
  }
}

class TranslateRecordImpl with MixInFileReader, MixInOutput, TranslateRecord {}

mixin UseTranslateRecord {
  TranslateRecord translateRecord;
}

mixin MixInTranslateRecord {
  final TranslateRecord translateRecord = TranslateRecordImpl();
}

class App with MixInTranslateRecord {
  void run(List<String> arg) {
    var argMap = arg.asMap();

    String csvFilePath;
    if (argMap.containsKey(0)) {
      csvFilePath = argMap[0];
    } else {
      throw new ArgumentError(
          "command line arg first must be set [csv file path]");
    }

    String recordFilePath;
    if (argMap.containsKey(1)) {
      recordFilePath = argMap[1];
    } else {
      throw new ArgumentError(
          "command line arg second must be set [record file path]");
    }

    print(
        "target csv file path = $csvFilePath, target record file path = $recordFilePath\n");

    print("--- Convert Result ---\n");

    translateRecord.execute(recordFilePath, csvFilePath, 5, 6);
  }
}

main(List<String> arguments) {
  App().run(arguments);
}
