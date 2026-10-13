import 'tr_en.dart';
import 'tr_es.dart';
import 'tr_fr.dart';
import 'tr_de.dart';
import 'tr_pt.dart';
import 'tr_ru.dart';
import 'tr_uk.dart';
import 'tr_pl.dart';
import 'tr_nl.dart';
import 'tr_tr.dart';
import 'tr_id.dart';
import 'tr_ja.dart';
import 'tr_ko.dart';
import 'tr_zh.dart';

/// Every translation table, by language code (Italian is the source and
/// lives in the code itself).
const translations = <String, Map<String, String>>{
  'en': trEn,
  'es': trEs,
  'fr': trFr,
  'de': trDe,
  'pt': trPt,
  'ru': trRu,
  'uk': trUk,
  'pl': trPl,
  'nl': trNl,
  'tr': trTr,
  'id': trId,
  'ja': trJa,
  'ko': trKo,
  'zh': trZh,
};
