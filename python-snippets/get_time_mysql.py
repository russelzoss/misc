#!/usr/bin/env python

import time, pymysql

host        = "localhost"
db_name     = "clock"
tab_name    = "timelog"
col_name    = "time"

connection = pymysql.connect(host=host)

try:
    with connection.cursor() as cursor:

        # Temporarily disable warnings
        cursor.execute("SET sql_notes = 0")

        sql = "CREATE DATABASE IF NOT EXISTS `{}`"
        cursor.execute(sql.format(db_name))

        sql = "CREATE TABLE IF NOT EXISTS `{}`.`{}` (id INT UNSIGNED NOT NULL AUTO_INCREMENT, {} DATETIME NOT NULL, PRIMARY KEY(id))"
        cursor.execute(sql.format(db_name, tab_name, col_name))

        # Re-enable warnings
        cursor.execute("SET sql_notes = 1")

        sql = "INSERT INTO `{}`.`{}` VALUES ('', '{}')"
        cursor.execute(sql.format(db_name, tab_name, time.strftime('%Y-%m-%d %H:%M:%S')))

    connection.commit()

finally:
    connection.close()

