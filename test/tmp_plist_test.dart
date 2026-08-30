import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

void main() {
  test('inspect playlists', () async {
    final db = AppDatabase(
      NativeDatabase(File(r'C:\Users\digor\AppData\Local\Temp\nebula_check2.db')),
    );
    final rows = await db.customSelect(
      'SELECT id, name, type, username, length(credential_key) as ck_len, '
      'substr(credential_key,1,4) as ck_head, epg_url IS NOT NULL AND epg_url != \'\' as has_epg '
      'FROM playlists',
    ).get();
    for (final r in rows) {
      // ignore: avoid_print
      print('playlist ${r.data}');
    }
    final groups = await db.customSelect(
      'SELECT (SELECT COUNT(*) FROM channel_groups) g, '
      '(SELECT COUNT(*) FROM channel_group_members) m',
    ).get();
    // ignore: avoid_print
    print('dedup groups/members: ${groups.first.data}');
    await db.close();
  });
}
