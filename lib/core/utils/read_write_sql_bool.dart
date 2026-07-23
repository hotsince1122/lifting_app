bool readSqliteBool(Object? value) => value == 1 || value == true;
int writeSqliteBool(bool? value) => value == true ? 1 : 0;