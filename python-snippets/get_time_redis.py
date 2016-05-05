#!/usr/bin/env python

import pymysql, redis

my_host        = "localhost"
my_port        = 3307
my_db_name     = "clock"
my_tab_name    = "timelog"
my_col_name    = "time"

r_host         = "localhost"
r_list_name    = "timelog"

my_conn = pymysql.connect(host=my_host, port=my_port)
r_server = redis.Redis(r_host)

try:
    with my_conn.cursor() as cursor:
        sql = "SELECT * FROM `{}`.`{}` ORDER BY id DESC LIMIT 1"
        cursor.execute(sql.format(my_db_name, my_tab_name))
        id, time = cursor.fetchone()
        r_server.rpush(r_list_name, time)

finally:
    my_conn.close()

