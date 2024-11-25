import requests
import json
import time
import psycopg2
import os
from time import sleep

#orleans = 'http://localhost:10111'
orleans = 'http://orleans:10111'
nowms = time.time()*1000.0

try:
    with psycopg2.connect(
        host="postgres",
        database="dual",
        user="dual",
        password="dual",
        port=5432
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM construct WHERE json_properties->'serverProperties'->>'isDynamicWreck' = 'true' and deleted_at > '2024-06-01 00:00:00+00' and deleted_at < now() - INTERVAL '10 DAYS'")
            print("The number of wrecks: ", cur.rowcount)
            row = cur.fetchone()

            while row is not None:
                cid = row[0]
                cname = row[1]
                row = cur.fetchone()
                sleep(0.1)
                
                print('deleting wreck', cid, cname)
                resp = requests.post(orleans + '/constructs/'+str(cid)+'/delete/hard', headers={'Accept': 'application/json'})
                #print(resp)

except (Exception, psycopg2.DatabaseError) as error:
    print(error)
